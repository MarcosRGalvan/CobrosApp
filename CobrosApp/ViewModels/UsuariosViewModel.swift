//
//  UsuariosViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 26/06/26.
//

import Foundation

@MainActor
@Observable
class UsuariosViewModel {
    var usuarios: [Usuario] = []
    var isLoading = false
    var errorMessage: String?
    var usuarioCreado = false
    var textoBusqueda: String = ""
    
    var nombre = ""
    var clave = ""
    var telefono = ""
    var direccion = ""
    
    var usuariosFiltrados: [Usuario] {
        if textoBusqueda.isEmpty {
            return usuarios
        }
        return usuarios.filter { $0.nombre.lowercased().contains(textoBusqueda.lowercased()) }
    }
    
    private let authService = AuthService()
    
    func cargarUsuarios() async {
        isLoading = true
        do {
            usuarios = try await authService.fetchUsuarios()
        } catch {
            errorMessage = "No se pudieron cargar los usuarios: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func crearCobrador(organizacionId: UUID, claveOrg: String) async {
        guard !nombre.isEmpty else {
            errorMessage = "El nombre es obligatorio"
            return
        }
        guard !clave.isEmpty else {
            errorMessage = "La clave es obligatoria"
            return
        }
        
        isLoading = true
        do {
            try await authService.crearCobrador(
                nombre: nombre,
                clave: clave,
                telefono: telefono.isEmpty ? nil : telefono,
                direccion: direccion.isEmpty ? nil : direccion,
                organizacionId: organizacionId,
                claveOrg: claveOrg
            )
            usuarioCreado = true
            limpiarFormulario()
        } catch {
            errorMessage = "No se pudo crear el cobrador: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func limpiarFormulario() {
        nombre = ""
        clave = ""
        telefono = ""
        direccion = ""
    }
}
