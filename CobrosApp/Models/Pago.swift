//
//  Pago.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/05/26.
//

import Foundation

struct Pago: Identifiable, Codable, Hashable {
    let id: Int?
    let prestamoId: Int
    let fechaPago: Date?
    let montoPagado: Double
    let abonoCapital: Double?
    let pagoIntereses: Double?
    let recargos: Double?
    let numeroCuota: Int?
    let fechaVencimiento: Date?
    let referenciaPago: String?
    let formaPagoId: Int?
    let prestamos: PrestamoAnidado?
    let organizacionId: UUID?
    let fechaVisitaSinPago: Date?
    let cobradorId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case prestamoId = "prestamo_id"
        case fechaPago = "fecha_pago"
        case montoPagado = "monto_pagado"
        case abonoCapital = "abono_capital"
        case pagoIntereses = "pago_intereses"
        case recargos
        case numeroCuota = "numero_cuota"
        case fechaVencimiento = "fecha_vencimiento"
        case referenciaPago = "referencia_pago"
        case formaPagoId = "forma_pago_id"
        case prestamos = "prestamos"
        case organizacionId = "organizacion_id"
        case fechaVisitaSinPago = "fecha_visita_sin_pago"
        case cobradorId = "cobrador_id"
    }

    var nombreCliente: String {
        guard let cliente = prestamos?.clientes else {
            return "Préstamos #\(prestamoId)"
        }
        return "\(cliente.nombre) \(cliente.appaterno)"
    }
}

struct PrestamoAnidado: Codable, Hashable {
    let prestamoId: Int
    let montoPrestado: Double
    let cuotas: Int
    let interesPorciento: Double
    let clientes: ClienteAnidado?

    enum CodingKeys: String, CodingKey {
        case prestamoId = "prestamo_id"
        case montoPrestado = "monto_prestado"
        case cuotas
        case interesPorciento = "interes_porciento"
        case clientes
    }
}
