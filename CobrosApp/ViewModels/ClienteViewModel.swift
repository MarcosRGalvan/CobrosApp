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
            let fecthClientes: [Cliente] = try await SupabaseManager.shared.client
                .from("clientes")
                .select()
                .execute()
                .value
            
            await MainActor.run {
                self.clientes = fecthClientes
                self.isLoading = false
            }
        } catch {
            print("❌ Error detallado de Supabase: \(error)")
            print(String(describing: error))

            await MainActor.run {
                self.errorMessage = "No se pudieron cargar los clientes: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    
    // Insertar un nuevo cliente
    func crearCliente(_ cliente: Cliente) async -> Bool {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            try await SupabaseManager.shared.client
                .from("clientes")
                .insert(cliente)
                .execute()
            
            // si se guardo actualizamos la lista
            await fetchClientes()
            return true
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Error al registrar cliente: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
}
