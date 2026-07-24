//
//  RutaService.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 16/07/26.
//

import Foundation
import Supabase

class RutaService {
    private let supabase = SupabaseManager.shared.client
    
    // Fetch todas las rutas de la organización (admin)
    func fetchRutas() async throws -> [Ruta] {
        return try await supabase
            .from("rutas")
            .select()
            .order("nombre")
            .execute()
            .value
    }
    
    // Fetch la ruta asignada al cobrador autenticado
    func fetchMiRuta() async throws -> Ruta? {
        guard let userId = supabase.auth.currentUser?.id else { return nil }
        
        let rutas: [Ruta] = try await supabase
            .from("rutas")
            .select()
            .eq("cobrador_id", value: userId.uuidString)
            .eq("activo", value: true)
            .limit(1)
            .execute()
            .value
        
        return rutas.first
    }
    
    // Crear nueva ruta (solo admin)
    func crearRuta(nombre: String, organizacionId: UUID) async throws -> Ruta {
        struct RutaInsert: Encodable {
            let nombre: String
            let organizacion_id: UUID
            let activo: Bool = true
        }
        
        return try await supabase
            .from("rutas")
            .insert(RutaInsert(nombre: nombre, organizacion_id: organizacionId))
            .select()
            .single()
            .execute()
            .value
    }
    
    // Asignar cobrador a una ruta (solo admin)
    func asignarCobrador(rutaId: UUID, cobradorId: UUID?) async throws {
        let valor: AnyJSON = cobradorId != nil
            ? AnyJSON.string(cobradorId!.uuidString)
            : AnyJSON.null
        
        try await supabase
            .from("rutas")
            .update(["cobrador_id": valor])
            .eq("id", value: rutaId.uuidString)
            .execute()
    }
    
    // Habilitar/deshabilitar ruta (solo admin)
    func toggleActivo(rutaId: UUID, activo: Bool) async throws {
        try await supabase
            .from("rutas")
            .update(["activo":activo])
            .eq("id", value: rutaId.uuidString)
            .execute()
    }
    
    // Asignar cliente a una ruta
    func asignarClienteARuta(clienteId: Int, rutaId: UUID) async throws {
        try await supabase
            .from("clientes")
            .update(["ruta_id": rutaId.uuidString])
            .eq("id", value: clienteId)
            .execute()
    }
    
    // Quitar cliente de su ruta
    func quitarClienteDeRuta(clienteId: Int) async throws {
        try await supabase
            .from("clientes")
            .update(["ruta_id": AnyJSON.null])
            .eq("id", value: clienteId)
            .execute()
    }
    
    // Fetch clientes de una ruta especifica
    func fetchClientesDeRuta(rutaId: UUID) async throws -> [Cliente] {
        return try await supabase
            .from("clientes")
            .select()
            .eq("ruta_id", value: rutaId.uuidString)
            .order("appaterno")
            .execute()
            .value
    }
    
    // Fetch ruta del cobrador actual para usarla al crear clientes
    func fetchRutaIdDelCobrador() async throws -> UUID? {
        guard let userId = supabase.auth.currentUser?.id else { return nil }

        struct RutaId: Decodable {
            let id: UUID
        }

        let response = try await supabase
            .from("rutas")
            .select("id")
            .eq("cobrador_id", value: userId.uuidString)
            .eq("activo", value: true)
            .limit(1)
            .execute()

        //print("📦 Raw rutaIdDelCobrador: \(String(data: response.data, encoding: .utf8) ?? "nil")")

        let rutas = try JSONDecoder().decode([RutaId].self, from: response.data)

        return rutas.first?.id
    }
    
    func fetchConteoClientesPorRuta() async throws -> [UUID: Int] {
        struct RutaConteo: Decodable {
            let rutaId: UUID
            enum CodingKeys: String, CodingKey {
                case rutaId = "ruta_id"
            }
        }

        let response: [RutaConteo] = try await supabase
            .from("clientes")
            .select("ruta_id")
            .not("ruta_id", operator: .is, value: "null")
            .execute()
            .value

        return Dictionary(grouping: response, by: { $0.rutaId })
            .mapValues { $0.count }
    }
    
    
    func fetchClientesSinRuta() async throws -> [Cliente] {
        return try await supabase
            .from("clientes")
            .select()
            .is("ruta_id", value: nil)
            .order("appaterno")
            .execute()
            .value
    }
    
}
