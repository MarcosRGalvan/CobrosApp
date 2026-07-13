//
//  OrganizacionesViewModel.swift
//  CobrosAdmin
//
//  Created by Marco Ramirez on 10/07/26.
//

import Foundation

@Observable
@MainActor
class OrganizacionesViewModel {
    var organizaciones: [Organizacion] = []
    var organizacionSeleccionada: Organizacion?
    var isLoading = false
    var errorMessage: String?
    var mostrarCrearOrg = false
    var orgCreada = false
    
    // Campos para crear
    var nombreNuevaOrg = ""
    var claveGenerada = ""
    
    private let service = OrganizacionesService()
    
    func cargarOrganizaciones() async {
        isLoading = true
        do {
            organizaciones = try await service.fetchOrganizaciones()
        } catch {
            errorMessage = "No se pudieron cargar las organizaciones: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func generarClave() {
        claveGenerada = service.generarClaveOrganizacion()
    }
    
    func crearOrganizacion() async {
        guard !nombreNuevaOrg.isEmpty else {
            errorMessage = "El nombre es obligatorio"
            return
        }
        guard !claveGenerada.isEmpty else {
            errorMessage = "Genera una clave primero"
            return
        }
        isLoading = true
        do {
            _ = try await service.crearOrganizacion(
                nombre: nombreNuevaOrg,
                clave: claveGenerada
            )
            orgCreada = true
            nombreNuevaOrg = ""
            claveGenerada = ""
            mostrarCrearOrg = false
            await cargarOrganizaciones()
        } catch {
            errorMessage = "No se pudo crear: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
