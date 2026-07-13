//
//  Organizacion.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 25/06/26.
//

import Foundation

struct Organizacion: Identifiable, Codable, Hashable {
    let id: UUID
    let nombre: String
    let clave: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case nombre
        case clave
        case createdAt = "created_at"
    }
}
