//
//  DetalleUsuarioViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 15/07/26.
//

import Foundation

@Observable
@MainActor
class DetalleUsuarioViewModel {
    let usuario: Usuario
    
    var totalCobros: Int = 0
    var totalRecaudo: Double = 0
    var isLoading = false
    var errorMessage: String?
    var fechaSeleccionada: Date = Date()
    
    private let pagoService = PagoService()
    
    init(usuario: Usuario) {
        self.usuario = usuario
    }
    
    func cargarEstadisticas() async {
        isLoading = true
        do {
            let stats = try await pagoService.fetchEstadisticasCobrador(
                cobradorId: usuario.id,
                fecha: fechaSeleccionada
            )
            totalCobros = stats.totalCobros
            totalRecaudo = stats.totalRecaudado
        } catch {
            errorMessage = "No se pudieron cargar los datos del cobrador: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
