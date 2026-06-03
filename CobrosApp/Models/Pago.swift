//
//  Pago.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/05/26.
//

import Foundation

struct Pago: Identifiable, Codable {
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
    let vencido: Bool
    let prestamos: PrestamoAnidado?

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
        case vencido
        case prestamos = "prestamos"
    }

    var nombreCliente: String {
        guard let cliente = prestamos?.clientes else {
            return "Préstamos #\(prestamoId)"
        }
        return "\(cliente.nombre) \(cliente.appaterno)"
    }
}

struct PrestamoAnidado: Codable {
    let prestamoId: Int
    let clientes: ClienteAnidado?

    enum CodingKeys: String, CodingKey {
        case prestamoId = "prestamo_id"
        case clientes
    }
}
