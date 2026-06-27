//
//  Prestamo.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 21/05/26.
//

import Foundation

struct Prestamo: Identifiable, Codable {
    var id: Int?
    var clienteId: Int
    var montoPrestado: Double
    var cuotas: Int
    var fechaPrestamo: Date
    var frecuenciaPago: Int
    var interesPorciento: Double
    var fechaTermino: Date?
    var activo: Bool
    var organizacionId: UUID?
    var cliente: ClienteAnidado?
    
    enum CodingKeys: String, CodingKey {
        case id = "prestamo_id"
        case clienteId = "cliente_id"
        case montoPrestado = "monto_prestado"
        case cuotas
        case fechaPrestamo = "fecha_prestamo"
        case frecuenciaPago = "frecuencia_pago"
        case interesPorciento = "interes_porciento"
        case fechaTermino = "fecha_termino"
        case activo
        case cliente = "clientes"
        case organizacionId = "organizacion_id"
    }
    
    var nombreCompletoCliente: String {
        if let cliente = cliente {
            return "\(cliente.nombre) \(cliente.apmaterno ?? "") \(cliente.apmaterno ?? "")"
        }
        return "Cargando cliente..."
    }
    
    
    func toDictionary() -> [String: Any] {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            var dict: [String: Any] = [
                "cliente_id": clienteId,
                "monto_prestado": montoPrestado,
                "cuotas": cuotas,
                "fecha_prestamo": formatter.string(from: fechaPrestamo),
                "frecuencia_pago": frecuenciaPago,
                "interes_porciento": interesPorciento,
                "fecha_termino": formatter.string(from: fechaTermino!),
                "activo": activo
            ]
            
            if let id = id {
                dict["id"] = id
            }
            
            return dict
        }
    
}


struct ClienteAnidado: Codable, Hashable {
    var nombre: String
    var appaterno: String
    var apmaterno: String?
    var telefono: String?
    var direccion: String?
    var email: String?
}


extension Prestamo {
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }
}
