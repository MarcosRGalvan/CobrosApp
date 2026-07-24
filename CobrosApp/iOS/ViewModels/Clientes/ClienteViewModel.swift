//
//  ClienteViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 19/05/26.
//

import Foundation
import Supabase

@Observable
class ClienteViewModel {
    var clientes: [Cliente] = []
    var textoBusqueda: String = ""
    
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    // Filtrar clientes
    var clientesFiltrados: [Cliente] {
        if textoBusqueda.isEmpty {
            return clientes
        } else {
            return clientes.filter { cliente in
                let nombreCompleto = "\(cliente.nombre) \(cliente.appaterno) \(cliente.apmaterno ?? "")"
                let coincideNombre = nombreCompleto.lowercased().contains(textoBusqueda.lowercased())
                let coincideTelefono = cliente.telefono.contains(textoBusqueda)
                
                return coincideNombre || (coincideTelefono)
            }
        }
    }
    
    // Obtener todos los clientes de la tabla clientes
    func fetchClientes() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let rutaService = RutaService()
            let rutaId = try await rutaService.fetchRutaIdDelCobrador()
            
            var query = SupabaseManager.shared.client
                .from("clientes")
                .select()
            
            if let rutaId = rutaId {
                query = query.eq("ruta_id", value: rutaId.uuidString)
            }
            
            let fetchClientes: [Cliente] = try await query
                .execute()
                .value
            
            await MainActor.run {
                self.clientes = fetchClientes
                self.isLoading = false
            }
        } catch {
            //print("❌ Error detallado de Supabase: \(error)")
            //print(String(describing: error))
            
            await MainActor.run {
                self.errorMessage = "No se pudieron cargar los clientes: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    
    // Insertar un nuevo cliente
    func crearCliente(_ cliente: Cliente) async -> Cliente? {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Obtenemos la organización del usuario actual
            guard let userId = SupabaseManager.shared.client.auth.currentUser?.id else {
                await MainActor.run {
                    self.errorMessage = "No hay sesión activa"
                    self.isLoading = false
                }
                return nil
            }
            
            struct OrgRow: Decodable { let organizacion_id: UUID }
            let orgRow: OrgRow = try await SupabaseManager.shared.client
                .from("usuarios")
                .select("organizacion_id")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            var clienteConOrg = cliente
            clienteConOrg.organizacionId = orgRow.organizacion_id
            
            //print("🏢 organizacionId a insertar: \(String(describing: clienteConOrg.organizacionId))")
            //print("👤 userId: \(userId)")
            
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            if let data = try? encoder.encode(clienteConOrg),
               let json = String(data: data, encoding: .utf8) {
                //print("📤 JSON a insertar: \(json)")
            }
            
            let clienteCreado: [Cliente] = try await SupabaseManager.shared.client
                .from("clientes")
                .insert(clienteConOrg, returning: .representation)
                .select()
                .execute()
                .value
            
            await fetchClientes()
            return clienteCreado.first
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Error al registrar cliente: \(error.localizedDescription)"
                self.isLoading = false
            }
            return nil
        }
    }
    
    // funcion para validar los campos obligatorios del formulario antes de enviarlos
    func validarCliente(nombre: String, appaterno: String, telefono: String, direccion: String) -> Bool {
        if nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.errorMessage = "El nombre es obligatorio."
            return false
        }
        if appaterno.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.errorMessage = "Se necesita al menos un apellido."
            return false
        }
        if telefono.trimmingCharacters(in: .whitespacesAndNewlines).count != 10 {
            self.errorMessage = "El teléfono debe tener 10 dígitos."
            return false
        }
        if direccion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.errorMessage = "La dirección de cobro es obligatoria."
            return false
        }
        return true
    }
    
    // Actualizar un cliente existente
    func actualizarCliente(_ cliente: Cliente) async -> Cliente? {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        guard let clienteId = cliente.id else {
            await MainActor.run {
                self.errorMessage = "No se puede actualizar un cliente sin ID"
                self.isLoading = false
            }
            return nil
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            if let data = try? encoder.encode(cliente),
               let json = String(data: data, encoding: .utf8) {
                // print("📤 JSON a actualizar: \(json)")
            }
            
            let clienteActualizado: [Cliente] = try await SupabaseManager.shared.client
                .from("clientes")
                .update(cliente, returning: .representation)
                .eq("id", value: clienteId)
                .select()
                .execute()
                .value
            
            await fetchClientes()
            return clienteActualizado.first
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Error al actualizar el cliente: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return nil
        }
    }
}
