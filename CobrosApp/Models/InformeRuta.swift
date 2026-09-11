//
//  InformeRuta.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 10/09/26.
//

import Foundation

struct InformeRuta: Identifiable {
    let id: UUID
    let nombreRuta: String
    let cobradorNombre: String?
    let totalClientes: Int
    let cobrosRealizados: Int
    let cobrosNoRealizados: Int
    let totalRecaudado: Double
    let cajaInicialTotal: Double
}

enum RangoInforme: String, CaseIterable, Identifiable {
    case hoy = "Hoy"
    case semana = "Esta semana"
    case mes = "Este mes"
    case personalizado = "Personalizado"
    
    var id: String { rawValue }
}
