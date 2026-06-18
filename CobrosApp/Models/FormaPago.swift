//
//  FormaPago.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 17/06/26.
//

import Foundation

struct FormaPago: Identifiable, Codable {
    var id: Int?
    var descripcion: String
    var activo: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "form_pago_id"
        case descripcion
        case activo
    }
}
