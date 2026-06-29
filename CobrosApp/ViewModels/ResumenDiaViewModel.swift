//
//  ResumenDiaViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 27/06/26.
//

import Foundation

@Observable
@MainActor
class ResumenDiaViewModel {
    var resumen: ResumenDia?
    var isLoading = false
    var errorMessage: String?
    
    private let pagoService = PagoService()
    
    func cargarResumen(cobradorId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            resumen = try await pagoService.fetchResumenDia(cobradorId: cobradorId)
        } catch {
            errorMessage = "No se pudo cargar el resumen: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
