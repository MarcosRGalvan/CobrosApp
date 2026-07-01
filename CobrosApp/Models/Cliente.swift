//
//  Cliente.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 19/05/26.
//

import Foundation

struct Cliente: Identifiable, Codable, Hashable {
    var id: Int?
    var nombre: String
    var appaterno: String
    var apmaterno: String?
    var telefono: String
    var direccion: String?
    var email: String?
    var organizacionId: UUID?
    var latitud: Double?
    var longitud: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case nombre
        case appaterno
        case apmaterno
        case telefono
        case direccion
        case email
        case organizacionId = "organizacion_id"
        case latitud
        case longitud
    }
}
