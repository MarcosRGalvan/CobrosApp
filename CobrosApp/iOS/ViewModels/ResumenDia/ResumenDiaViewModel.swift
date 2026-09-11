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
    private let prestamoService = PrestamoService()
    private let cajaService = CajaService()
    private let rutaService = RutaService()
    
    func cargarResumen(cobradorId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            async let resumenTask = pagoService.fetchResumenDia(cobradorId: cobradorId)
            async let totalPrestadoTask = prestamoService.totalPrestadoHoy()
            
            let (resumenBase, totalPrestado) = try await (resumenTask, totalPrestadoTask)
            
            var cajaInicial: Double? = nil
            if let rutaId = try await rutaService.fetchRutaIdDelCobrador() {
                cajaInicial = try await cajaService.fetchCajaHoy(rutaId: rutaId)
            }
            
            resumen = ResumenDia(
                cobrosRealizados: resumenBase.cobrosRealizados,
                cobrosPendientes: resumenBase.cobrosPendientes,
                cobrosSinPagar: resumenBase.cobrosSinPagar,
                totalRecaudado: resumenBase.totalRecaudado,
                efectividad: resumenBase.efectividad,
                totalPrestadoHoy: totalPrestado,
                cajaInicial: cajaInicial
            )
        } catch {
            errorMessage = "No se pudo cargar el resumen: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
