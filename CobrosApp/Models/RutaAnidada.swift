//
//  RutaAnidada.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 16/07/26.
//

import Foundation

struct RutaAnidada: Codable, Hashable {
    let id: UUID
    let nombre: String
    let activo: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case nombre
        case activo
    }
}
