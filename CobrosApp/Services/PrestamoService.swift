//
//  PrestamoService.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 29/06/26.
//

import Foundation
import Supabase

class PrestamoService {
    private let supabase = SupabaseManager.shared.client
    
    func finalizarPrestamo(prestamoId: Int) async throws {
        struct FinalizarPrestamo: Encodable {
            let activo: Bool
            let fecha_termino: String
        }
        
        let formatter = ISO8601DateFormatter()
        let payload = FinalizarPrestamo(
            activo: false,
            fecha_termino: formatter.string(from: Date())
        )
        
        try await supabase
            .from("prestamos")
            .update(payload)
            .eq("prestamo_id", value: prestamoId)
            .execute()
    }
}
