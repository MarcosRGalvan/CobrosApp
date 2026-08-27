//
//  DetalleClienteViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/06/26.
//

import Foundation
import Supabase

@Observable
@MainActor
class DetalleClienteViewModel {
    let cliente: Cliente
    var incumplimientos: Int = 0
    var score: Double = 0
    var isLoading = false
    var errorMessage: String?
    
    var documentoURL: URL?
    var cargandoDocumento: Bool = false
    
    var riesgo: RiesgoCrediticio {
        RiesgoCrediticio(score: score)
    }
    
    private let pagoService = PagoService()
    
    init(cliente: Cliente) {
        self.cliente = cliente
    }
    
    func cargarEstadisticas() async {
        guard let clienteId = cliente.id else { return }
        isLoading = true
        do {
            async let incumplimientosTask = pagoService.fetchIncumplimientos(clienteId: clienteId)
            async let scoresTask = pagoService.fetchScoresClientes(clienteIds: [clienteId])
            let (incumplimientosResult, scoresResult) = try await (incumplimientosTask, scoresTask)
            
            incumplimientos = incumplimientosResult
            score = scoresResult[clienteId] ?? 0
        } catch {
            errorMessage = "No se pudieron cargar las estadísticas: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func cargarDocumento(cliente: Cliente) async {
        guard let path = cliente.documentoPath else { return }
        
        await MainActor.run { self.cargandoDocumento = true }
        
        do {
            let url = try await SupabaseManager.shared.client.storage
                .from("identificaciones")
                .createSignedURL(path: path, expiresIn: 3600)
            
            await MainActor.run {
                self.documentoURL = url
                self.cargandoDocumento = false
            }
        } catch {
            await MainActor.run {
                self.cargandoDocumento = false
            }
        }
    }
}
