//
//  FormasPagoViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 17/06/26.
//

import Foundation
import Supabase

@Observable
class FormasPagoViewModel {
    var formasPago: [FormaPago] = []
    
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    func fetchFormasPago() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let fetchFormasPago: [FormaPago] = try await
            SupabaseManager.shared.client
                .from("formas_pago")
                .select()
                .execute()
                .value
            
            await MainActor.run {
                self.formasPago = fetchFormasPago
                self.isLoading = false
            }
        } catch {
            // print("❌ error detallado de Supabase: \(error)")
            // print(String(describing: error))
            
            await MainActor.run {
                self.errorMessage = "No se pudieron cargar las formas de pago: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}
