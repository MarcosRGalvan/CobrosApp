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
}
