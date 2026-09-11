//
//  InformeService.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 10/09/26.
//

import Foundation
import Supabase

class InformeService {
    private let supabase = SupabaseManager.shared.client
    
    func fetchInformeRutas(desde: Date, hasta: Date) async throws -> [InformeRuta] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "InformeService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa"])
        }
        
        struct OrgRow: Decodable { let organizacion_id: UUID }
        let orgRow: OrgRow = try await supabase
            .from("usuarios")
            .select("organizacion_id")
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        let isoFormatter = ISO8601DateFormatter()
        let desdeStr = isoFormatter.string(from: desde)
        let hastaStr = isoFormatter.string(from: hasta)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let desdeDateStr = dateFormatter.string(from: desde)
        let hastaDateStr = dateFormatter.string(from: hasta)
        
        // 1. Rutas de la organización, con nombre del cobrador
        struct RutaConCobrador: Decodable {
            let id: UUID
            let nombre: String
            let usuarios: NombreCobrador?
            
            struct NombreCobrador: Decodable {
                let nombre: String?
            }
        }
        
        let rutas: [RutaConCobrador] = try await supabase
            .from("rutas")
            .select("id, nombre, usuarios(nombre)")
            .eq("organizacion_id", value: orgRow.organizacion_id.uuidString)
            .execute()
            .value
        
        guard !rutas.isEmpty else { return [] }
        
        // 2. Clientes por ruta
        struct ClienteRuta: Decodable {
            let id: Int
            let rutaId: UUID?
            enum CodingKeys: String, CodingKey {
                case id
                case rutaId = "ruta_id"
            }
        }
        let clientes: [ClienteRuta] = try await supabase
            .from("clientes")
            .select("id, ruta_id")
            .eq("organizacion_id", value: orgRow.organizacion_id.uuidString)
            .execute()
            .value
        
        let clientesPorRuta = Dictionary(grouping: clientes) { $0.rutaId }
        let clienteToRuta: [Int: UUID] = Dictionary(uniqueKeysWithValues: clientes.compactMap { c in
            guard let r = c.rutaId else { return nil }
            return (c.id, r)
        })
        let allClienteIds = clientes.map { $0.id }
        
        // 3. Préstamos creados en el rango (para total prestado por ruta)
        struct PrestamoInfo: Decodable {
            let montoPrestado: Double
            let clienteId: Int
            enum CodingKeys: String, CodingKey {
                case montoPrestado = "monto_prestado"
                case clienteId = "cliente_id"
            }
        }
        let prestamos: [PrestamoInfo] = try await supabase
            .from("prestamos")
            .select("monto_prestado, cliente_id")
            .gte("fecha_prestamo", value: desdeDateStr)
            .lte("fecha_prestamo", value: hastaDateStr)
            .execute()
            .value
        
        let prestamoPorRuta = Dictionary(grouping: prestamos) { clienteToRuta[$0.clienteId] }
        
        // 4. Pagos con vencimiento en el rango (para recaudado + efectividad)
        struct PagoInfo: Decodable {
            let montoPagado: Double
            let estado: String
            let prestamos: PrestamoClienteId?
            struct PrestamoClienteId: Decodable {
                let clienteId: Int
                enum CodingKeys: String, CodingKey { case clienteId = "cliente_id" }
            }
            enum CodingKeys: String, CodingKey {
                case montoPagado = "monto_pagado"
                case estado
                case prestamos
            }
        }
        
        let pagosResponse = try await supabase
            .from("pagos")
            .select("monto_pagado, estado, prestamos!inner(cliente_id)")
            .gte("fecha_vencimiento", value: desdeStr)
            .lt("fecha_vencimiento", value: hastaStr)
            .execute()
        
        let pagos = try JSONDecoder().decode([PagoInfo].self, from: pagosResponse.data)
        let pagoPorRuta = Dictionary(grouping: pagos) { clienteToRuta[$0.prestamos?.clienteId ?? -1] }
        
        // 5. Scores e incumplimientos
        let pagoService = PagoService()
        let scores = try await pagoService.fetchScoresClientes(clienteIds: allClienteIds)
        let incumplimientos = try await pagoService.fetchIncumplimientosBulk(clienteIds: allClienteIds)
        
        
        // 6. Se arma el informe por ruta
        var informes: [InformeRuta] = []
        for ruta in rutas {
            let clientesRuta = clientesPorRuta[ruta.id] ?? []
            let clienteIdsRuta = Set(clientesRuta.map { $0.id })
            
            let totalPrestado = (prestamoPorRuta[ruta.id] ?? []).map { $0.montoPrestado }.reduce(0, +)
            
            let pagosRuta = pagoPorRuta[ruta.id] ?? []
            let cobrados = pagosRuta.filter { $0.estado == "pagado" }
            let totalRecaudado = cobrados.map { $0.montoPagado }.reduce(0, +)
            let efectividad = pagosRuta.isEmpty ? 0 : (Double(cobrados.count) / Double(pagosRuta.count)) * 100
            
            let clientesConIncumplimientos = clienteIdsRuta.filter { (incumplimientos[$0] ?? 0) > 0 }.count
            
            let scoresRuta = clienteIdsRuta.compactMap { scores[$0] }
            let scoresPromedio = scoresRuta.isEmpty ? 0 : scoresRuta.reduce(0, +) / Double(scoresRuta.count)
            
            informes.append(InformeRuta(
                id: ruta.id,
                nombreRuta: ruta.nombre,
                cobradorNombre: ruta.usuarios?.nombre,
                totalClientes: clientesRuta.count,
                totalPrestado: totalPrestado,
                totalRecaudado: totalRecaudado,
                efectividad: efectividad,
                clientesConIncumplimientos: clientesConIncumplimientos,
                scorePromedio: scoresPromedio
            ))
        }
        
        return informes.sorted { $0.nombreRuta < $1.nombreRuta }
    }
}
