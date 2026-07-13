//
//  DetalleClienteViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/06/26.
//

import Foundation

@Observable
@MainActor
class DetalleClienteViewModel {
    let cliente: Cliente
    var incumplimientos: Int = 0
    var score: Double = 0
    var isLoading = false
    var errorMessage: String?
    
    var scoreColor: String {
        switch score {
        case 80...100: return "green"
        case 50..<80: return "orange"
        default: return "red"
        }
    }
    
    var scoreDescription: String {
        switch score {
        case 80...100: return "Buen pagador"
        case 50..<80: return "Pago regular"
        default: return "Alto riesgo"
        }
    }
    
    private let pagoService = PagoService()
    
    init(cliente: Cliente) {
        self.cliente = cliente
    }
    
    func cargarEstadisticas() async {
        guard let clienteId = cliente.id else {
            print("❌ No hay clienteId")
            return
        }
        print("🔍 Cargando estadísticas para clienteId: \(clienteId)")
        isLoading = true
        do {
            async let incumplimientosTask = pagoService.fetchIncumplimientos(clienteId: clienteId)
            async let scoreTask = pagoService.fetchScoreCliente(clienteId: clienteId)
            (incumplimientos, score) = try await (incumplimientosTask, scoreTask)
            print("✅ Score: \(score), Incumplimientos: \(incumplimientos)")
        } catch {
            print("❌ Error: \(error)")
            errorMessage = "No se pudieron cargar las estadísticas: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
