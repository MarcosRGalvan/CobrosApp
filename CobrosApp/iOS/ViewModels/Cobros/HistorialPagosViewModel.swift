//
//  HistorialPagosViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/06/26.
//

import Foundation

@Observable
@MainActor
class HistorialPagosViewModel {
    var pagos: [Pago] = []
    var isLoading = false
    var errorMessage: String?
    
    private let pagoService = PagoService()
    
    func cargarHistorial(prestamoId: Int) async {
        isLoading = true
        do {
            pagos = try await pagoService.fetchHistorialPagos(prestamoId: prestamoId)
        } catch {
            errorMessage = "No se pudo cargar el historial: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
