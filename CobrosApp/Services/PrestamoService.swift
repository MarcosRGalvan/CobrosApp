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
    
    func totalPrestadoHoy() async throws -> Double {
        let hoy = Calendar.current.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let hoyStr = dateFormatter.string(from: hoy)
        
        struct MontoPrestado: Decodable {
            let montoPrestado: Double
            enum CodingKeys: String, CodingKey {
                case montoPrestado = "monto_prestado"
            }
        }
        
        let rutaService = RutaService()
        
        if let rutaId = try await rutaService.fetchRutaIdDelCobrador() {
            let response: [MontoPrestado] =
            try await supabase
                .from("prestamos")
                .select("monto_prestado")
                .eq("fecha_prestamo", value: hoyStr)
                .execute()
                .value
            
            return response.map { $0.montoPrestado }.reduce(0, +)
            
        } else {
            let response: [MontoPrestado] =
            try await supabase
                .from("prestamos")
                .select("monto_prestado")
                .eq("fecha_prestamo", value: hoyStr)
                .execute()
                .value
            
            return response.map { $0.montoPrestado }.reduce(0, +)
        }
    }
}
