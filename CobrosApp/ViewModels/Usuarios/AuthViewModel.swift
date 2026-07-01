//
//  AuthViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 26/06/26.
//

import Foundation

@Observable
@MainActor
class AuthViewModel {
    var usuarioActual: Usuario?
    var isLoading = false
    var errorMessage: String?
    
    var estaAutenticado: Bool{ usuarioActual != nil }
    var esAdmin: Bool { usuarioActual?.rol == .admin }
    
    private let authService = AuthService()
    
    func verificarSesion() async {
        isLoading = true
        do {
            usuarioActual = try await authService.fetchUsuarioActual()
        } catch {
            usuarioActual = nil
        }
        isLoading = false
    }
    
    
    func login(claveOrg: String, clave: String) async {
        isLoading = true
        errorMessage = nil
        do {
            usuarioActual = try await authService.login(claveOrg: claveOrg, clave: clave)
        } catch {
            errorMessage = "Clave de organización o contraseña incorrecta"
        }
        isLoading = false
    }
    
    
    func logout() async {
        do {
            try await authService.logout()
            usuarioActual = nil
        } catch {
            errorMessage = "No se pudo cerrar sesión"
        }
    }
}
