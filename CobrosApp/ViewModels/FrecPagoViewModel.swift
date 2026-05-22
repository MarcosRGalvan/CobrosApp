//
//  FrecPagoViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 22/05/26.
//

import Foundation
import Supabase

@Observable
class FrecPagoViewModel {
    var frecuencias: [FrecuenciaPag] = []
    
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    func fetchFrecuenciasPago() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let fetchFrecuenciasPago: [FrecuenciaPag] = try await SupabaseManager.shared.client
                .from("frecuencias_pago")
                .select()
                .execute()
                .value
            
            await MainActor.run {
                self.frecuencias = fetchFrecuenciasPago
                self.isLoading = false
            }
        } catch {
            print("❌ Error detallado de Supabase: \(error)")
            print(String(describing: error))
            
            await MainActor.run {
                self.errorMessage = "No se pudieron cargar los clientes: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}
