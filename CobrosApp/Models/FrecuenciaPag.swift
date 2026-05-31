//
//  FrecuenciaPag.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 22/05/26.
//

import Foundation

struct FrecuenciaPag: Identifiable, Codable {
    var id: Int?
    var nombre: String
    var activo: Bool
    
    var diasIntervalo: Int {
        switch nombre.lowercased() {
        case "diario": return 1
        case "semanal": return 7
        case "quincenal": return 15
        case "mensual": return 30
        default: return 0
        }
    }
}
