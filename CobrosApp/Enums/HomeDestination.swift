//
//  HomeDestination.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 19/05/26.
//

import Foundation

enum HomeDestination: Hashable {
    case clientes
    case prestamos
    case pagos
    case rutaDelDia
    case crearPrestamo(Cliente?)
}
