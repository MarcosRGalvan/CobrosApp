//
//  Usuario.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 25/06/26.
//

import Foundation

struct Usuario: Identifiable, Codable {
    let id: UUID
    let organizacionId: UUID
    let nombre: String
    let clave: String
    let rol: RolUsuario
    let direccion: String?
    let telefono: String?
    let activo: Bool
    let rutaAsignada: RutaAnidada?
    
    enum CodingKeys: String, CodingKey {
        case id
        case organizacionId = "organizacion_id"
        case nombre
        case clave
        case rol
        case direccion
        case telefono
        case activo
        case rutaAsignada = "rutas"
    }
}

enum RolUsuario: String, Codable {
    case admin
    case cobrador
    case desarrollador
}
