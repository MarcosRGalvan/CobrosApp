//
//  Prestamo.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 21/05/26.
//

import Foundation

struct Prestamo: Identifiable, Codable, Hashable {
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

    init(
        id: Int? = nil,
        clienteId: Int,
        montoPrestado: Double,
        cuotas: Int,
        fechaPrestamo: Date,
        frecuenciaPago: Int,
        interesPorciento: Double,
        fechaTermino: Date? = nil,
        activo: Bool,
        organizacionId: UUID? = nil,
        cliente: ClienteAnidado? = nil
    ) {
        self.id = id
        self.clienteId = clienteId
        self.montoPrestado = montoPrestado
        self.cuotas = cuotas
        self.fechaPrestamo = fechaPrestamo
        self.frecuenciaPago = frecuenciaPago
        self.interesPorciento = interesPorciento
        self.fechaTermino = fechaTermino
        self.activo = activo
        self.organizacionId = organizacionId
        self.cliente = cliente
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        clienteId = try container.decode(Int.self, forKey: .clienteId)
        montoPrestado = try container.decode(Double.self, forKey: .montoPrestado)
        cuotas = try container.decode(Int.self, forKey: .cuotas)
        fechaPrestamo = try container.decode(Date.self, forKey: .fechaPrestamo)
        frecuenciaPago = try container.decode(Int.self, forKey: .frecuenciaPago)
        interesPorciento = try container.decode(Double.self, forKey: .interesPorciento)
        fechaTermino = try container.decodeIfPresent(Date.self, forKey: .fechaTermino)
        activo = try container.decode(Bool.self, forKey: .activo)
        organizacionId = try container.decodeIfPresent(UUID.self, forKey: .organizacionId)

        // Supabase a veces embebe la relación "clientes" como objeto y a veces
        // como array de un elemento (relación ambigua para PostgREST); se aceptan ambas formas.
        if let clienteObjeto = try? container.decodeIfPresent(ClienteAnidado.self, forKey: .cliente) {
            cliente = clienteObjeto
        } else if let clienteArreglo = try? container.decodeIfPresent([ClienteAnidado].self, forKey: .cliente) {
            cliente = clienteArreglo.first
        } else {
            cliente = nil
        }
    }

    var nombreCompletoCliente: String {
        if let cliente = cliente {
            return "\(cliente.nombre) \(cliente.appaterno) \(cliente.apmaterno ?? "")"
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
    var rutaId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case nombre
        case appaterno
        case apmaterno
        case telefono
        case direccion
        case email
        case rutaId = "ruta_id"  // ← nuevo
    }
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
