//
//  Ruta.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 16/07/26.
//

import Foundation

struct Ruta: Identifiable, Codable, Hashable {
    let id: UUID
    let nombre: String
    let cobradorId: UUID?
    let activo: Bool
    let organizacionId: UUID
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case nombre
        case cobradorId = "cobrador_id"
        case activo
        case organizacionId = "organizacion_id"
        case createdAt = "created_at"
    }
}
