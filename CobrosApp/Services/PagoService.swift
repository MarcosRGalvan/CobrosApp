//
//  PagoService.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/05/26.
//

import Foundation
import Supabase

struct ActualizarPago: Encodable {
    let fechaPago: String
    let montoPagado: Double
    let formaPagoId: Int?
    let abonoCapital: Double
    let pagoIntereses: Double
    let recargos: Double
    let cobradorId: String
    let estado: String = "pagado"

    enum CodingKeys: String, CodingKey {
        case fechaPago = "fecha_pago"
        case montoPagado = "monto_pagado"
        case formaPagoId = "forma_pago_id"
        case abonoCapital = "abono_capital"
        case pagoIntereses = "pago_intereses"
        case recargos
        case cobradorId = "cobrador_id"
        case estado
    }
}

struct PagoInsert: Encodable {
    let prestamo_id: Int
    let monto_pagado: Double
    let numero_cuota: Int
    let fecha_vencimiento: String
    let organizacion_id: UUID
    let estado: String = "pendiente"
}

class PagoService {
    private let supabase = SupabaseManager.shared.client

    // Genera todos los pagos al crear un préstamo
    func generarCuotas(
        prestamoId: Int,
        prestamo: Prestamo,
        frecuencia: FrecuenciaPag
    ) async throws {
        //print("diasIntervalo recibido: \(frecuencia.diasIntervalo)")
        //print("fechaPrestamo: \(prestamo.fechaPrestamo)")

        guard frecuencia.diasIntervalo > 0, prestamo.cuotas > 0 else { return }
        guard let orgId = prestamo.organizacionId else {
            throw NSError(
                domain: "PagoService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Sin organizacion_id"]
            )
        }

        let calendar = Calendar.current
        let fechaBase = calendar.startOfDay(for: prestamo.fechaPrestamo)
        let isoFormatter = ISO8601DateFormatter()

        let montoPorCuota =
            ((prestamo.montoPrestado * (1 + prestamo.interesPorciento / 100))
            / Double(prestamo.cuotas))
            .rounded(toPlaces: 2)

        var pagos: [PagoInsert] = []

        for i in 1...prestamo.cuotas {
            guard
                let fechaVence = calendar.date(
                    byAdding: .day,
                    value: frecuencia.diasIntervalo * i,
                    to: fechaBase
                )
            else { continue }

            pagos.append(
                PagoInsert(
                    prestamo_id: prestamoId,
                    monto_pagado: montoPorCuota,
                    numero_cuota: i,
                    fecha_vencimiento: isoFormatter.string(from: fechaVence),
                    organizacion_id: orgId
                )
            )
        }

        try await supabase
            .from("pagos")
            .insert(pagos)
            .execute()
    }

    // Pagos pendientes (hoy y vencidos anteriores)
    func fetchCobrosDiarios() async throws -> [Pago] {
        let hoy = Calendar.current.startOfDay(for: Date())
        let manana = Calendar.current.date(byAdding: .day, value: 1, to: hoy)!
        let formatter = ISO8601DateFormatter()
        let hasta = formatter.string(from: manana)

        let rutaService = RutaService()

        // Si tiene ruta asignada filtra por ella
        if let rutaId = try await rutaService.fetchRutaIdDelCobrador() {
            // Obtener IDs de préstamos de clientes de esa ruta
            struct PrestamoId: Decodable { let prestamo_id: Int }
            let prestamos: [PrestamoId] =
                try await supabase
                .from("prestamos")
                .select("prestamo_id, clientes!inner(ruta_id)")
                .eq("clientes.ruta_id", value: rutaId.uuidString)
                .execute()
                .value

            let ids = prestamos.map { $0.prestamo_id }

            guard !ids.isEmpty else { return [] }

            let response =
                try await supabase
                .from("pagos")
                .select(
                    """
                        *,
                        prestamos (
                            prestamo_id,
                            monto_prestado,
                            cuotas,
                            interes_porciento,
                            clientes (
                                nombre,
                                appaterno,
                                apmaterno,
                                telefono,
                                direccion,
                                email,
                                ruta_id
                            )
                        )
                    """
                )
                .lt("fecha_vencimiento", value: hasta)
                .eq("estado", value: "pendiente")
                .in("prestamo_id", values: ids)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Pago].self, from: response.data)

        } else {
            // Admin ve todo
            let response =
                try await supabase
                .from("pagos")
                .select(
                    """
                        *,
                        prestamos (
                            prestamo_id,
                            monto_prestado,
                            cuotas,
                            interes_porciento,
                            clientes (
                                nombre,
                                appaterno,
                                apmaterno,
                                telefono,
                                direccion,
                                email,
                                ruta_id
                            )
                        )
                    """
                )
                .lt("fecha_vencimiento", value: hasta)
                .eq("estado", value: "pendiente")
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Pago].self, from: response.data)
        }
    }

    // Marca un pago como cobrado
    func registrarPago(
        pagoId: Int,
        monto: Double,
        formaPagoId: Int?,
        abonoCapital: Double,
        pagoIntereses: Double,
        recargos: Double
    ) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(
                domain: "PagoService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa"]
            )
        }

        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        let payload = ActualizarPago(
            fechaPago: formatter.string(from: Date()),
            montoPagado: monto,
            formaPagoId: formaPagoId,
            abonoCapital: abonoCapital,
            pagoIntereses: pagoIntereses,
            recargos: recargos,
            cobradorId: userId.uuidString
        )

        try await supabase
            .from("pagos")
            .update(payload)
            .eq("id", value: pagoId)
            .execute()
    }
    
    func saldoRestanteTotal(prestamoId: Int) async throws -> Double {
        struct MontoPago: Decodable {
            let montoPagado: Double
            enum CodingKeys: String, CodingKey {
                case montoPagado = "monto_pagado"
            }
        }
        
        let response: [MontoPago] = try await supabase
            .from("pagos")
            .select("monto_pagado")
            .eq("prestamo_id", value: prestamoId)
            .neq("estado", value: "pagado")
            .execute()
            .value
        
        return response.map { $0.montoPagado }.reduce(0, +).rounded(toPlaces: 2)
    }

    // Marca que el cobrador visitó al cliente pero no hubo pago
    func marcarSinPago(pagoId: Int) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(
                domain: "PagoService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa"]
            )
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        
        try await supabase
            .from("pagos")
            .update([
                "estado": AnyJSON.string("sin_pagar"),
                "fecha_visita_sin_pago": AnyJSON.string(formatter.string(from: Date())),
                "cobrador_id": AnyJSON.string(userId.uuidString),
            ])
            .eq("id", value: pagoId)
            .execute()
    }

    // Total de pagos realizados para un préstamo
    func totalPagosRealizados(prestamoId: Int) async throws -> Int {
        let response =
            try await supabase
            .from("pagos")
            .select("id", head: false, count: .exact)
            .eq("prestamo_id", value: prestamoId)
            .not("fecha_pago", operator: .is, value: "null")
            .execute()

        return response.count ?? 0
    }

    // Saldo pagado de capital para un préstamo
    func saldoPendiente(prestamoId: Int) async throws -> Double {
        struct SaldoPendiente: Decodable {
            let abonoCapital: Double?
            enum CodingKeys: String, CodingKey {
                case abonoCapital = "abono_capital"
            }
        }

        let response: [SaldoPendiente] =
            try await supabase
            .from("pagos")
            .select("abono_capital")
            .eq("prestamo_id", value: prestamoId)
            .not("fecha_pago", operator: .is, value: "null")
            .execute()
            .value

        return response.compactMap { $0.abonoCapital }.reduce(0, +)
    }

    func fetchResumenDia(cobradorId: UUID) async throws -> ResumenDia {
        let hoy = Calendar.current.startOfDay(for: Date())
        let manana = Calendar.current.date(byAdding: .day, value: 1, to: hoy)!
        let formatter = ISO8601DateFormatter()
        let desde = formatter.string(from: hoy)
        let hasta = formatter.string(from: manana)

        struct PagoResumen: Decodable {
            let fechaPago: Date?
            let montoPagado: Double
            let estado: String
            enum CodingKeys: String, CodingKey {
                case fechaPago = "fecha_pago"
                case montoPagado = "monto_pagado"
                case estado
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let rutaService = RutaService()

        let pagos: [PagoResumen]

        // Igual que en fetchCobrosDiarios: si tiene ruta asignada, filtra por ella
        if let rutaId = try await rutaService.fetchRutaIdDelCobrador() {
            struct PrestamoId: Decodable { let prestamo_id: Int }
            let prestamos: [PrestamoId] =
                try await supabase
                .from("prestamos")
                .select("prestamo_id, clientes!inner(ruta_id)")
                .eq("clientes.ruta_id", value: rutaId.uuidString)
                .execute()
                .value

            let ids = prestamos.map { $0.prestamo_id }
            guard !ids.isEmpty else {
                return ResumenDia(cobrosRealizados: 0, cobrosPendientes: 0, cobrosSinPagar: 0, totalRecaudado: 0, efectividad: 0, totalPrestadoHoy: 0, cajaInicial: nil)
            }

            let response =
                try await supabase
                .from("pagos")
                .select("fecha_pago, monto_pagado, estado")
                .gte("fecha_vencimiento", value: desde)   // ← NUEVO: acota a hoy
                .lt("fecha_vencimiento", value: hasta)
                .in("prestamo_id", values: ids)            // ← NUEVO: acota a su ruta
                .execute()

            pagos = try decoder.decode([PagoResumen].self, from: response.data)

        } else {
            // Admin ve el resumen de toda la organización
            let response =
                try await supabase
                .from("pagos")
                .select("fecha_pago, monto_pagado, estado")
                .gte("fecha_vencimiento", value: desde)   // ← NUEVO
                .lt("fecha_vencimiento", value: hasta)
                .execute()

            pagos = try decoder.decode([PagoResumen].self, from: response.data)
        }

        let cobrados = pagos.filter { $0.estado == "pagado" }
        let sinPagar = pagos.filter { $0.estado == "sin_pagar" }
        let pendientes = pagos.filter { $0.estado == "pendiente" }
        
        let totalRecaudado = cobrados.map { $0.montoPagado }.reduce(0, +)
        let totalAsignados = pagos.count
        let efectividad = totalAsignados > 0
            ? (Double(cobrados.count) / Double(totalAsignados)) * 100
            : 0

        return ResumenDia(
            cobrosRealizados: cobrados.count,
            cobrosPendientes: pendientes.count,
            cobrosSinPagar: sinPagar.count,
            totalRecaudado: totalRecaudado,
            efectividad: efectividad,
            totalPrestadoHoy: 0,
            cajaInicial: nil
        )
    }

    func fetchIncumplimientosBulk(clienteIds: [Int]) async throws -> [Int: Int] {
        guard !clienteIds.isEmpty else { return [:] }
        
        struct PrestamoClienteId: Decodable {
            let prestamoId: Int
            let clienteId: Int
            enum CodingKeys: String, CodingKey {
                case prestamoId = "prestamo_id"
                case clienteId = "cliente_id"
            }
        }
        let prestamos: [PrestamoClienteId] = try await supabase
            .from("prestamos")
            .select("prestamo_id, cliente_id")
            .in("cliente_id", values: clienteIds)
            .execute()
            .value
        
        guard !prestamos.isEmpty else { return [:] }
        let prestamoToCliente = Dictionary(uniqueKeysWithValues: prestamos.map { ($0.prestamoId, $0.clienteId) })
        let allPrestamoIds = prestamos.map { $0.prestamoId }
        
        let hoy = Calendar.current.startOfDay(for: Date())
        
        struct PagoFechas: Decodable {
            let prestamoId: Int
            let fechaPago: Date?
            let fechaVencimiento: Date?
            enum CodingKeys: String, CodingKey {
                case prestamoId = "prestamo_id"
                case fechaPago = "fecha_pago"
                case fechaVencimiento = "fecha_vencimiento"
            }
        }
        
        let response = try await supabase
            .from("pagos")
            .select("prestamo_id, fecha_pago, fecha_vencimiento")
            .in("prestamo_id", values: allPrestamoIds)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pagos = try decoder.decode([PagoFechas].self, from: response.data)
        
        var resultado: [Int: Int] = [:]
        let calendar = Calendar.current
        
        for pago in pagos {
            guard let clienteId = prestamoToCliente[pago.prestamoId] else { continue }
            var esIncumplimiento = false
            
            if let fechaVence = pago.fechaVencimiento, pago.fechaPago == nil {
                if calendar.startOfDay(for: fechaVence) < hoy { esIncumplimiento = true }
            } else if let fechaPago = pago.fechaPago, let fechaVence = pago.fechaVencimiento {
                if calendar.startOfDay(for: fechaPago) > calendar.startOfDay(for: fechaVence) { esIncumplimiento = true }
            }
            
            if esIncumplimiento {
                resultado[clienteId, default: 0] += 1
            }
        }
        
        return resultado
    }
    
    struct PagoConCliente: Decodable {
        let fechaPago: Date?
        let fechaVencimiento: Date?
        let prestamos: PrestamoClienteId?

        struct PrestamoClienteId: Decodable {
            let clienteId: Int
            enum CodingKeys: String, CodingKey {
                case clienteId = "cliente_id"
            }
        }

        enum CodingKeys: String, CodingKey {
            case fechaPago = "fecha_pago"
            case fechaVencimiento = "fecha_vencimiento"
            case prestamos
        }
    }

    func fetchScoresClientes(clienteIds: [Int]) async throws -> [Int: Double] {
        guard !clienteIds.isEmpty else { return [:] }

        let hoy = Calendar.current.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()
        let hastaHoy = formatter.string(from: hoy)

        let response =
            try await supabase
            .from("pagos")
            .select("fecha_pago, fecha_vencimiento, prestamos!inner(cliente_id)")
            .in("prestamos.cliente_id", values: clienteIds)
            .lt("fecha_vencimiento", value: hastaHoy)
            .execute()
        
        // print("📦 Raw response scores: \(String(data: response.data, encoding: .utf8) ?? "nil")")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pagos = try decoder.decode([PagoConCliente].self, from: response.data)

        let agrupados = Dictionary(grouping: pagos) { $0.prestamos?.clienteId ?? -1 }

        var scores: [Int: Double] = [:]
        for (clienteId, pagosCliente) in agrupados where clienteId != -1 {
            let total = pagosCliente.count
            guard total > 0 else { continue }
            let aTiempo = pagosCliente.filter { pago in
                guard let fechaPago = pago.fechaPago, let fechaVence = pago.fechaVencimiento else { return false }
                let calendar = Calendar.current
                return calendar.startOfDay(for: fechaPago) <= calendar.startOfDay(for: fechaVence)
            }.count
            scores[clienteId] = (Double(aTiempo) / Double(total)) * 100
        }
        
        return scores
    }
    
    func fetchCobrosDelDiaPorEstado(estado: String) async throws -> [Pago] {
        let hoy = Calendar.current.startOfDay(for: Date())
        let manana = Calendar.current.date(byAdding: .day, value: 1, to: hoy)!
        let formatter = ISO8601DateFormatter()
        let desde = formatter.string(from: hoy)
        let hasta = formatter.string(from: manana)

        let rutaService = RutaService()
        let select = """
                *,
                prestamos (
                    prestamo_id,
                    monto_prestado,
                    cuotas,
                    interes_porciento,
                    clientes (
                        nombre,
                        appaterno,
                        apmaterno,
                        telefono,
                        direccion,
                        email,
                        ruta_id
                    )
                )
            """

        if let rutaId = try await rutaService.fetchRutaIdDelCobrador() {
            // Obtener IDs de préstamos de clientes de esa ruta
            struct PrestamoId: Decodable { let prestamo_id: Int }
            let prestamos: [PrestamoId] =
                try await supabase
                .from("prestamos")
                .select("prestamo_id, clientes!inner(ruta_id)")
                .eq("clientes.ruta_id", value: rutaId.uuidString)
                .execute()
                .value

            let ids = prestamos.map { $0.prestamo_id }
            guard !ids.isEmpty else { return [] }

            let response =
                try await supabase
                .from("pagos")
                .select(select)
                .gte("fecha_vencimiento", value: desde)
                .lt("fecha_vencimiento", value: hasta)
                .eq("estado", value: estado)
                .in("prestamo_id", values: ids)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Pago].self, from: response.data)

        } else {
            // Admin ve todo
            let response =
                try await supabase
                .from("pagos")
                .select(select)
                .gte("fecha_vencimiento", value: desde)
                .lt("fecha_vencimiento", value: hasta)
                .eq("estado", value: estado)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Pago].self, from: response.data)
        }
    }
    func fetchHistorialPagos(prestamoId: Int) async throws -> [Pago] {
        let response =
            try await supabase
            .from("pagos")
            .select("*")
            .eq("prestamo_id", value: prestamoId)
            .order("numero_cuota", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Pago].self, from: response.data)
    }

    // Corrige un pago ya registrado (solo admin) sin alterar la fecha original
    func actualizarPagoExistente(
        pagoId: Int,
        fechaPagoOriginal: Date,
        monto: Double,
        formaPagoId: Int,
        abonoCapital: Double,
        abonoIntereses: Double,
        recargos: Double,
        cobradorIdOriginal: String
    ) async throws {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        let payload = ActualizarPago(
            fechaPago: formatter.string(from: fechaPagoOriginal),
            montoPagado: monto,
            formaPagoId: formaPagoId,
            abonoCapital: abonoCapital,
            pagoIntereses: abonoIntereses,
            recargos: recargos,
            cobradorId: cobradorIdOriginal
        )

        try await supabase
            .from("pagos")
            .update(payload)
            .eq("id", value: pagoId)
            .execute()
    }

    // Revertir pago a su estado inicial en caso de equivocación del cobrador
    // Vuelve a dejar el pago en pendiente por cobrar
    func revertirPago(pagoId: Int) async throws {
        try await supabase
            .from("pagos")
            .update([
                "fecha_pago": AnyJSON.null,
                "forma_pago_id": AnyJSON.null,
                "abono_capital": AnyJSON.null,
                "pago_intereses": AnyJSON.null,
                "recargos": AnyJSON.null,
                "cobrador_id": AnyJSON.null,
                "fecha_visita_sin_pago": AnyJSON.null,
                "estado": AnyJSON.string("pendiente"),  // ← vuelve a pendiente
            ])
            .eq("id", value: pagoId)
            .execute()
    }

    func fetchEstadisticasCobrador(cobradorId: UUID, fecha: Date) async throws
        -> (totalCobros: Int, totalRecaudado: Double)
    {
        let calendar = Calendar.current
        let inicioDia = calendar.startOfDay(for: fecha)
        let finDia = calendar.date(byAdding: .day, value: 1, to: inicioDia)!

        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current

        struct MontoPago: Decodable {
            let montoPagado: Double
            enum CodingKeys: String, CodingKey {
                case montoPagado = "monto_pagado"
            }
        }

        let response: [MontoPago] =
            try await supabase
            .from("pagos")
            .select("monto_pagado")
            .eq("cobrador_id", value: cobradorId.uuidString)
            .gte("fecha_pago", value: formatter.string(from: inicioDia))
            .lt("fecha_pago", value: formatter.string(from: finDia))
            .not("fecha_pago", operator: .is, value: "null")
            .execute()
            .value

        return (response.count, response.map { $0.montoPagado }.reduce(0, +))
    }
    
    func totalCuotasResuletas(prestamoId: Int) async throws -> Int {
        let response = try await supabase
            .from("pagos")
            .select("id", head: false, count: .exact)
            .eq("prestamo_id", value: prestamoId)
            .neq("estado", value: "pendiente")
            .execute()
        
        return response.count ?? 0
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
