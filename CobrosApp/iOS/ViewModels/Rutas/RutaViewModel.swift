//
//  RutasViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 17/07/26.
//

import Foundation

@Observable
@MainActor
class RutaViewModel {
    var rutas: [Ruta] = []
    var miRuta: Ruta?
    var isLoading = false
    var errorMessage: String?
    var conteoClientes: [UUID: Int] = [:]
    
    var nombreNuevaRuta = ""
    var mostrarCrearRuta = false
    var rutaCreada = false
    
    private let service = RutaService()
    
    // MARK: - Admin
    
    func cargarRutas() async {
        isLoading = true
        do {
            async let rutasTask = service.fetchRutas()
            async let conteoTask = service.fetchConteoClientesPorRuta()
            (rutas, conteoClientes) = try await (rutasTask, conteoTask)
        } catch {
            errorMessage = "No se pudieron cargar las ruta: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func clientesEnRuta(_ rutaId: UUID) -> Int {
        conteoClientes[rutaId] ?? 0
    }
    
    func createRuta(organizacionId: UUID) async {
        guard !nombreNuevaRuta.isEmpty else {
            errorMessage = "El nombre es obligatorio"
            return
        }
        isLoading = true
        do {
            let ruta = try await service.crearRuta(
                nombre: nombreNuevaRuta,
                organizacionId: organizacionId
            )
            rutas.append(ruta)
            rutaCreada = true
            nombreNuevaRuta = ""
            mostrarCrearRuta = false
        } catch {
            errorMessage = "No se pudo crear la ruta: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func asignarCobrador(rutaId: UUID, cobradorId: UUID?) async {
        do {
            try await service.asignarCobrador(rutaId: rutaId, cobradorId: cobradorId)
            await cargarRutas()
        } catch {
            errorMessage = "No se pudo asignar el cobrador: \(error.localizedDescription)"
        }
    }
    
    func toggleActivo(ruta: Ruta) async {
        do {
            try await service.toggleActivo(rutaId: ruta.id, activo: !ruta.activo)
            await cargarRutas()
        } catch {
            errorMessage = "No se pudo actualizar la ruta: \(error.localizedDescription)"
        }
    }
    
    
    // MARK: - Cobrador
    
    func cargarMiRuta() async {
        isLoading = true
        do {
            miRuta = try await service.fetchMiRuta()
        } catch {
            errorMessage = "No se pudo cargar tu ruta: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    
    // MARK: - Filtros
    
    var rutasActivas: [Ruta] {
        rutas.filter { $0.activo }
    }
    
    var rutasInactivas: [Ruta] {
        rutas.filter { !$0.activo }
    }
}
