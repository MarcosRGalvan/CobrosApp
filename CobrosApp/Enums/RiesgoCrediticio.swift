//
//  RiesgoCrediticio.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 27/08/26.
//

import Foundation
import SwiftUI

enum RiesgoCrediticio {
    case buenPagador
    case pagoRegular
    case altoRiesgo
    case sinHistorial
    
    init(score: Double?) {
        guard let score else {
            self = .sinHistorial
            return
        }
        switch score {
        case 75...100: self = .buenPagador
        case 50..<75: self = .pagoRegular
        default: self = .altoRiesgo
        }
    }
    
    var color: Color {
        switch self {
        case .buenPagador: return .green
        case .pagoRegular: return .orange
        case .altoRiesgo: return .red
        case .sinHistorial: return .gray.opacity(0.4)
        }
    }
    
    var descripcion: String {
        switch self {
        case .buenPagador: return "Buen pagador"
        case .pagoRegular: return "Pago regular"
        case .altoRiesgo: return "Alto riesgo"
        case .sinHistorial: return "Sin historial"
        }
    }
}
