//
//  PrestamoViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 21/05/26.
//

import Foundation
import Supabase

@Observable
@MainActor
class PrestamoViewModel {
    var prestamos: [Prestamo] = []
    var textoBusqueda: String = ""
    
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    func fetchPrestamos() async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            decoder.dateDecodingStrategy = .formatted(formatter)
            
            let response = try await SupabaseManager.shared.client
                .from("prestamos")
                .select("""
                    *,
                    clientes (
                        id,
                        nombre,
                        appaterno,
                        apmaterno
                    )
                    """)
                .order("fecha_prestamo", ascending: false)
                .execute()
            
            let fetchPrestamos = try decoder.decode([Prestamo].self, from: response.data)
            
            self.prestamos = fetchPrestamos
            self.isLoading = false
        } catch {
            print("❌ Error detallado de Supabase (Préstamos): \(error)")
            
            self.errorMessage = "Error al cargar la lista de préstamos: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func crearPrestamo(_ prestamo: Prestamo) async -> Bool {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            try await SupabaseManager.shared.client
                .from("prestamos")
                .insert(prestamo)
                .execute()
            
            return true
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Error al crear el prestamo \( error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    // Validamos los campos del formulario antes de insertar
    func validarPrestamo(
        clienteId: Int?,
        monto: Double,
        cuotas: Int,
        intereses: Double
    ) -> Bool {
        guard let id = clienteId, id != 0 else {
            self.errorMessage = "Error: no se ha seleccionado un cliente."
            return false
        }
        if monto <= 0 {
            self.errorMessage = "El monto prestado debe ser mayor a $0.00."
            return false
        }
        if cuotas <= 0 {
            self.errorMessage = "El número de cuotas debe ser por lo menos de 1"
            return false
        }
        if intereses < 0 {
            self.errorMessage = "El porcentaje de interés no puede ser un número negativo."
            return false
        }
        
        return true
    }
}
