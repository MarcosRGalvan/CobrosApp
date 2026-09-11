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
        let rutaIds = rutas.map { $0.id }
        
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
        
        // 3. Pagos con vencimiento en el rango
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
        
        // 4. Caja inicial sumada en el rango, en bulk
        let cajaService = CajaService()
        let cajasPorRuta = try await cajaService.fetchCajasEnRangoBulk(rutaIds: rutaIds, desde: desde, hasta: hasta)
        
        // 5. Armar el informe por ruta
        var informes: [InformeRuta] = []
        for ruta in rutas {
            let clientesRuta = clientesPorRuta[ruta.id] ?? []
            let pagosRuta = pagoPorRuta[ruta.id] ?? []
            
            let realizados = pagosRuta.filter { $0.estado == "pagado" }
            let noRealizados = pagosRuta.filter { $0.estado != "pagado" }
            let totalRecaudado = realizados.map { $0.montoPagado }.reduce(0, +)
            
            informes.append(InformeRuta(
                id: ruta.id,
                nombreRuta: ruta.nombre,
                cobradorNombre: ruta.usuarios?.nombre,
                totalClientes: clientesRuta.count,
                cobrosRealizados: realizados.count,
                cobrosNoRealizados: noRealizados.count,
                totalRecaudado: totalRecaudado,
                cajaInicialTotal: cajasPorRuta[ruta.id] ?? 0
            ))
        }
        
        return informes.sorted { $0.nombreRuta < $1.nombreRuta }
    }
}
