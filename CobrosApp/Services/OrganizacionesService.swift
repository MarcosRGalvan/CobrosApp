//
//  OrganizacionesService.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 10/07/26.
//

import Foundation
import Supabase

class OrganizacionesService {
    private let supabase = SupabaseManager.shared.client
    
    func fetchOrganizaciones() async throws -> [Organizacion] {
        return try await supabase
            .from("organizaciones")
            .select()
            .order("nombre")
            .execute()
            .value
    }
    
    func crearOrganizacion(nombre: String, clave: String) async throws -> Organizacion {
        struct OrganizacionInsert: Encodable {
            let nombre: String
            let clave: String
        }
        
        let payload = OrganizacionInsert(nombre: nombre, clave: clave)
        
        return try await supabase
            .from("organizaciones")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }
    
    func generarClaveOrganizacion() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
    
    func fetchCobradores(organizacionId: UUID) async throws -> [Usuario] {
        return try await supabase
            .from("usuarios")
            .select()
            .eq("organizacion_id", value: organizacionId.uuidString)
            .eq("rol", value: "cobrador")
            .execute()
            .value
    }

    func fetchTotalClientes(organizacionId: UUID) async throws -> Int {
        let response = try await supabase
            .from("clientes")
            .select("id", head: false, count: .exact)
            .eq("organizacion_id", value: organizacionId.uuidString)
            .execute()
        return response.count ?? 0
    }
    
    func fetchPrestamosActivos(organizacionId: UUID) async throws -> Int {
        let response = try await supabase
            .from("prestamos")
            .select("prestamo_id", head: false, count: .exact)
            .eq("organizacion_id", value: organizacionId.uuidString)
            .eq("activo", value: true)
            .execute()
        return response.count ?? 0
    }
    
    func fetchRecaudadoMes(organizacionId: UUID) async throws -> Double {
        let calendar = Calendar.current
        let inicioMes = calendar.date(
            from: calendar.dateComponents([.year, .month], from: Date())
        )!
        let formatter = ISO8601DateFormatter()
        
        struct MontoPago: Decodable {
            let montoPagado: Double
            enum CodingKeys: String, CodingKey {
                case montoPagado = "monto_pagado"
            }
        }
        
        let response: [MontoPago] = try await supabase
            .from("pagos")
            .select("monto_pagado")
            .eq("organizacion_id", value: organizacionId.uuidString)
            .gte("fecha_pago", value: formatter.string(from: inicioMes))
            .not("fecha_pago", operator: .is, value: "null")
            .execute()
            .value
        
        return response.map { $0.montoPagado }.reduce(0, +)
    }
}
