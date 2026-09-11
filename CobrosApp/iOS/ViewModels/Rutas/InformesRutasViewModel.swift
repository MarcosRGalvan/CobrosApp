//
//  InformesRutasViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 11/09/26.
//

import Foundation

@Observable
@MainActor
class InformesRutasViewModel {
    var informes: [InformeRuta] = []
    var isLoading = false
    var errorMessage: String?
    
    var rangoSeleccionado: RangoInforme = .hoy
    var fechaInicio: Date = Calendar.current.startOfDay(for: Date())
    var fechaFin: Date = Date()
    var mostrarSelectorPersonalizado = false
    
    private let informeService = InformeService()
    
    func seleccionarRango(_ rango: RangoInforme) {
        rangoSeleccionado = rango
        let calendar = Calendar.current
        let hoy = calendar.startOfDay(for: Date())
        
        switch rango {
        case .hoy:
            fechaInicio = hoy
            fechaFin = calendar.date(byAdding: .day, value: 1, to: hoy)!
            Task { await cargarInformes() }
        case .semana:
            fechaInicio = calendar.date(byAdding: .day, value: -7, to: hoy)!
            fechaFin = calendar.date(byAdding: .day, value: 1, to: hoy)!
            Task { await cargarInformes() }
        case .mes:
            fechaInicio = calendar.date(byAdding: .month, value: -1, to: hoy)!
            fechaFin = calendar.date(byAdding: .day, value: 1, to: hoy)!
            Task { await cargarInformes() }
        case .personalizado:
            mostrarSelectorPersonalizado = true
        }
    }
    
    func cargarInformes() async {
        isLoading = true
        errorMessage = nil
        do {
            informes = try await informeService.fetchInformeRutas(desde: fechaInicio, hasta: fechaFin)
        } catch {
            errorMessage = "No se pudieron cargar los informes: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
