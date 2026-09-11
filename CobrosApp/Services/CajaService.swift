//
//  CajaService.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 10/09/26.
//

import Foundation
import Supabase

struct CajaRuta: Codable {
    let id: Int?
    let rutaId: UUID
    let fecha: String
    let montoInicial: Double
    let asignadoPor: UUID?
    let organizacionId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id
        case rutaId = "ruta_id"
        case fecha
        case montoInicial = "monto_inicial"
        case asignadoPor = "asignado_por"
        case organizacionId = "organizacion_id"
    }
}

class CajaService {
    private let supabase = SupabaseManager.shared.client
    
    private var hoyStr: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
    
    // Admin asigna o corrige la caja del dia para una ruta
    func asignarCaja(rutaId: UUID, monto: Double, organizacionId: UUID) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "CajaService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa"])
        }
        
        struct CajaInsert: Encodable {
            let ruta_id: String
            let fecha: String
            let monto_inicial: Double
            let asignado_por: String
            let organizacion_id: String
        }
        
        let payload = CajaInsert(
            ruta_id: rutaId.uuidString,
            fecha: hoyStr,
            monto_inicial: monto,
            asignado_por: userId.uuidString,
            organizacion_id: organizacionId.uuidString
        )
        
        try await supabase
            .from("cajas_ruta")
            .upsert(payload, onConflict: "ruta_id,fecha")
            .execute()
    }
    
    // Consulta la caja asignada hoy para una ruta (nil si no se ha asignado)
    func fetchCajaHoy(rutaId: UUID) async throws -> Double? {
        struct MontoCaja: Decodable {
            let montoInicial: Double
            enum CodingKeys: String, CodingKey {
                case montoInicial = "monto_inicial"
            }
        }
        
        let response: [MontoCaja] =
        try await supabase
            .from("cajas_ruta")
            .select("monto_inicial")
            .eq("ruta_id", value: rutaId.uuidString)
            .eq("fecha", value: hoyStr)
            .execute()
            .value
        
        return response.first?.montoInicial
    }
    
    // Efectivo esperado en caja: inicial + cobros en efectivo del dia
    func fetchEfectivoEsperado(rutaId: UUID) async throws -> Double {
        let cajaInicial = try await fetchCajaHoy(rutaId: rutaId) ?? 0
        
        let hoy = Calendar.current.startOfDay(for: Date())
        let manana = Calendar.current.date(byAdding: .day, value: 1, to: hoy)!
        let isoFormatter = ISO8601DateFormatter()
        
        struct PrestamoId: Decodable { let prestamo_id: Int }
        let prestamos: [PrestamoId] =
        try await supabase
            .from("prestamos")
            .select("prestamo_id, clientes!inner(rutaId)")
            .eq("clientes.ruta_id", value: rutaId.uuidString)
            .execute()
            .value
        
        let ids = prestamos.map { $0.prestamo_id }
        guard !ids.isEmpty else { return cajaInicial }
        
        struct MontoPago: Decodable {
            let montoPagado: Double
            enum CodingKeys: String, CodingKey {
                case montoPagado = "monto_pagado"
            }
        }
        
        let response: [MontoPago] =
        try await supabase
            .from("pagos")
            .select("monto_pagado, formas_pago!inner(descripcion)")
            .in("prestamo_id", values: ids)
            .eq("formas_pago.descripcion", value: "EFECTIVO")
            .gte("fecha_pago", value: isoFormatter.string(from: hoy))
            .lt("fecha_pago", value: isoFormatter.string(from: manana))
            .execute()
            .value
        
        let totalEfectivo = response.map { $0.montoPagado }.reduce(0, +)
        return cajaInicial + totalEfectivo
    }
    
    func fetchCajasEnRangoBulk(rutaIds: [UUID], desde: Date, hasta: Date) async throws -> [UUID: Double] {
        guard !rutaIds.isEmpty else { return [:] }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let desdeStr = dateFormatter.string(from: desde)
        let hastaStr = dateFormatter.string(from: hasta)
        
        struct CajaRow: Decodable {
            let rutaId: UUID
            let montoInicial: Double
            enum CodingKeys: String, CodingKey {
                case rutaId = "ruta_id"
                case montoInicial = "monto_inicial"
            }
        }
        
        let response: [CajaRow] = try await supabase
            .from("cajas_ruta")
            .select("ruta_id, monto_inicial")
            .in("ruta_id", values: rutaIds.map { $0.uuidString })
            .gte("fecha", value: desdeStr)
            .lte("fecha", value: hastaStr)
            .execute()
            .value
        
        var resultado: [UUID: Double] = [:]
        for row in response {
            resultado[row.rutaId, default: 0] += row.montoInicial
        }
        return resultado
    }
}
