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

struct PagoInsert: Encodable {
    let prestamo_id: Int
    let monto_pagado: Double
    let numero_cuota: Int
    let fecha_vencimiento: String
    let organizacion_id: UUID
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
        guard let orgId = prestamo.organizacionId else {
            throw NSError(domain: "PagoService", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Sin organizacion_id"])
        }

        let calendar = Calendar.current
        let fechaBase = calendar.startOfDay(for: prestamo.fechaPrestamo)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let montoPorCuota = ((prestamo.montoPrestado * (1 + prestamo.interesPorciento / 100)) / Double(prestamo.cuotas))
            .rounded(toPlaces: 2)

        var pagos: [PagoInsert] = []

        for i in 1...prestamo.cuotas {
            guard let fechaVence = calendar.date(
                byAdding: .day,
                value: frecuencia.diasIntervalo * i,
                to: fechaBase
            ) else { continue }

            pagos.append(PagoInsert(
                prestamo_id: prestamoId,
                monto_pagado: montoPorCuota,
                numero_cuota: i,
                fecha_vencimiento: formatter.string(from: fechaVence),
                organizacion_id: orgId
            ))
        }

        try await supabase
            .from("pagos")
            .insert(pagos)
            .execute()
    }

    // Pagos pendientes (hoy y vencidos anteriores)
    func fetchCobrosDiarios() async throws -> [Pago] {
        let hoy = Calendar.current.startOfDay(for: Date())
        let manana = Calendar.current.date(byAdding: .day, value: 1, to: hoy)!

        let formatter = ISO8601DateFormatter()
        let hasta = formatter.string(from: manana)

        let response = try await supabase
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
            .lt("fecha_vencimiento", value: hasta)
            //.is("fecha_pago", value: nil)
            .execute()

        print("📦 Raw response: \(String(data: response.data, encoding: .utf8) ?? "nil")")

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

    // Marca un pago como cobrado
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

    // Total de pagos realizados para un préstamo
    func totalPagosRealizados(prestamoId: Int) async throws -> Int {
        let response = try await supabase
            .from("pagos")
            .select("id", head: false, count: .exact)
            .eq("prestamo_id", value: prestamoId)
            .not("fecha_pago", operator: .is, value: "null")
            .execute()

        return response.count ?? 0
    }

    // Saldo pagado de capital para un préstamo
    func saldoPendiente(prestamoId: Int) async throws -> Double {
        struct SaldoPendiente: Decodable {
            let abonoCapital: Double?
            enum CodingKeys: String, CodingKey {
                case abonoCapital = "abono_capital"
            }
        }

        let response: [SaldoPendiente] = try await supabase
            .from("pagos")
            .select("abono_capital")
            .eq("prestamo_id", value: prestamoId)
            .not("fecha_pago", operator: .is, value: "null")
            .execute()
            .value

        return response.compactMap { $0.abonoCapital }.reduce(0, +)
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
