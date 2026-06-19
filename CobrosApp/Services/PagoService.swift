//
//  PagoService.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/05/26.
//

import Foundation
import Supabase

struct ActualizarPago: Encodable {
    let fechaPago: String
    let montoPagado: Double
    let formaPagoId: Int?
    let abonoCapital: Double
    let pagoIntereses: Double
    let recargos: Double
    
    enum CodingKeys: String, CodingKey {
        case fechaPago = "fecha_pago"
        case montoPagado = "monto_pagado"
        case formaPagoId = "forma_pago_id"
        case abonoCapital = "abono_capital"
        case pagoIntereses = "pago_intereses"
        case recargos
    }
}

class PagoService {
    private let supabase = SupabaseManager.shared.client

    // Genera todos los pagos al crear un préstamo
    func generarCuotas(
        prestamoId: Int,
        prestamo: Prestamo,
        frecuencia: FrecuenciaPag
    ) async throws {
        print("diasIntervalo recibido: \(frecuencia.diasIntervalo)")
        print("fechaPrestamo: \(prestamo.fechaPrestamo)")
        
        guard frecuencia.diasIntervalo > 0, prestamo.cuotas > 0 else { return }
        
        let calendar = Calendar.current
        let fechaBase = calendar.startOfDay(for: prestamo.fechaPrestamo)
        
        let montoPorCuota = ((prestamo.montoPrestado * (1 + prestamo.interesPorciento / 100)) / Double(prestamo.cuotas))
            .rounded(toPlaces: 2)
        
        var pagos: [Pago] = []

        for i in 1...prestamo.cuotas {
            guard
                let fechaVence = calendar.date(
                    byAdding: .day,
                    value: frecuencia.diasIntervalo * i,
                    to: fechaBase
                )
            else { continue }

            pagos.append(
                Pago(
                    id: nil,
                    prestamoId: prestamoId,
                    fechaPago: nil,
                    montoPagado: montoPorCuota,
                    abonoCapital: nil,
                    pagoIntereses: nil,
                    recargos: nil,
                    numeroCuota: i,
                    fechaVencimiento: fechaVence,
                    referenciaPago: nil,
                    formaPagoId: nil,
                    prestamos: nil
                )
            )
        }

        try await supabase
            .from("pagos")
            .insert(pagos)
            .execute()
    }

    // Pagos que vencen hoy y no han sido cobrados
    func fetchCobrosDiarios() async throws -> [Pago] {
        let hoy = Calendar.current.startOfDay(for: Date())
        let manana = Calendar.current.date(byAdding: .day, value: 1, to: hoy)!

        let formatter = ISO8601DateFormatter()
        let desde = formatter.string(from: hoy)
        let hasta = formatter.string(from: manana)

        print("🗓 Buscando cobros entre: \(desde) y \(hasta)")

        let response =
            try await supabase
            .from("pagos")
            .select("""
                *,
                prestamos (
                    prestamo_id,
                    monto_prestado,
                    cuotas,
                    interes_porciento,
                    clientes (
                        nombre,
                        appaterno,
                        apmaterno,
                        telefono,
                        direccion,
                        email
                        )
                    )
            """)
            .gte("fecha_vencimiento", value: desde)
            .lt("fecha_vencimiento", value: hasta)
            .execute()

        print(
            "📦 Raw response: \(String(data: response.data, encoding: .utf8) ?? "nil")"
        )

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let pagos = try decoder.decode([Pago].self, from: response.data)
            print("✅ Decode exitoso: \(pagos.count) pagos")
            return pagos
        } catch {
            print("❌ Error de decode: \(error)")
            throw error
        }
    }
    
    // Marca un pago como cobrado: registra fecha, monto y forma de pago
    func registrarPago(
        pagoId: Int,
        monto: Double,
        formaPagoId: Int?,
        abonoCapital: Double,
        pagoIntereses: Double,
        recargos: Double
    ) async throws {
        let formatter = ISO8601DateFormatter()
        let payload = ActualizarPago(
            fechaPago: formatter.string(from: Date()),
            montoPagado: monto,
            formaPagoId: formaPagoId,
            abonoCapital: abonoCapital,
            pagoIntereses: pagoIntereses,
            recargos: recargos
        )
        
        try await supabase
            .from("pagos")
            .update(payload)
            .eq("id", value: pagoId)
            .execute()
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
