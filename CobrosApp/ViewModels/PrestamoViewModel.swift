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
            let response = try await SupabaseManager.shared.client
                .from("prestamos")
                .select(
                    """
                    *,
                    clientes (
                        id,
                        nombre,
                        appaterno,
                        apmaterno
                    )
                    """
                )
                .order("fecha_prestamo", ascending: false)
                .execute()

            self.prestamos = try Prestamo.decoder.decode([Prestamo].self, from: response.data)
            self.isLoading = false

        } catch is CancellationError {
            self.isLoading = false
        } catch {
            print("❌ Error detallado de Supabase (Préstamos): \(error)")
            self.errorMessage = "Error al cargar la lista de préstamos: \(error.localizedDescription)"
            self.isLoading = false
        }
    }

    func crearPrestamo(_ prestamo: Prestamo, frecuencia: FrecuenciaPag) async -> Bool {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            guard let userId = SupabaseManager.shared.client.auth.currentUser?.id else {
                self.errorMessage = "No hay sesión activa"
                self.isLoading = false
                return false
            }
            
            struct OrgRow: Decodable { let organizacion_id: UUID }
            let orgRow: OrgRow = try await SupabaseManager.shared.client
                .from("usuarios")
                .select("organizacion_id")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            var prestamoConOrg = prestamo
            prestamoConOrg.organizacionId = orgRow.organizacion_id
            
            let response = try await SupabaseManager.shared.client
                .from("prestamos")
                .insert(prestamoConOrg, returning: .representation)
                .select()
                .single()
                .execute()

            let prestamoCreado = try Prestamo.decoder.decode(Prestamo.self, from: response.data)

            guard let prestamoId = prestamoCreado.id else {
                self.errorMessage = "No se pudo obtener el ID del préstamo creado."
                self.isLoading = false
                return false
            }

            try await PagoService().generarCuotas(
                prestamoId: prestamoId,
                prestamo: prestamoConOrg,
                frecuencia: frecuencia
            )

            return true

        } catch {
            await MainActor.run {
                self.errorMessage = "Error al crear el prestamo \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }

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
