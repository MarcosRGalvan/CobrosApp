//
//  Organizacion.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 25/06/26.
//

import Foundation

struct Organizacion: Identifiable, Codable {
    let id: UUID
    let nombre: String
    let clave: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case nombre
        case clave
    }
}
