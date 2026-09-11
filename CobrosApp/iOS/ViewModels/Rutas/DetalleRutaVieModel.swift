//
//  DetalleRutaViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 17/07/26.
//

import Foundation

@Observable
@MainActor
class DetalleRutaViewModel {
    var ruta: Ruta
    var clientes: [Cliente] = []
    var cobrador: Usuario?
    var usuarios: [Usuario] = []
    var isLoading = false
    var errorMessage: String?

    // Estados para sheets
    var mostrarAsignarCobrador = false
    var mostrarAsignarClientes = false
    var mostrarConfirmacionMover: (cliente: Cliente, rutaDestino: Ruta)? = nil
    
    // Caja del dia
    var cajaHoy: Double?
    var cargandoCaja = false
    var mostrarAsignarCaja = false
    var montoCajaTexto: String = ""

    private let rutaService = RutaService()
    private let authService = AuthService()
    private let cajaService = CajaService()

    init(ruta: Ruta) {
        self.ruta = ruta
    }

    func cargarDatos() async {
        isLoading = true
        do {
            async let clientesTask = rutaService.fetchClientesDeRuta(rutaId: ruta.id)
            async let usuariosTask = authService.fetchUsuarios()
            let (c, u) = try await (clientesTask, usuariosTask)
            clientes = c
            usuarios = u
            if let cobradorId = ruta.cobradorId {
                cobrador = u.first { $0.id == cobradorId }
            }
        } catch is CancellationError {
             //print("⚠️ Cancelado")
        } catch {
            errorMessage = "Error cargando datos: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func cargarCajaHoy() async {
        cargandoCaja = true
        do {
            cajaHoy = try await cajaService.fetchCajaHoy(rutaId: ruta.id)
        } catch {
            errorMessage = "No se pudo cargar la caja del dia: \(error.localizedDescription)"
        }
        cargandoCaja = false
    }
    
    func guardarCaja() async {
        guard let monto = Double(montoCajaTexto), monto >= 0 else {
            errorMessage = "Inresa un monto válido"
            return
        }
        
        do {
            try await cajaService.asignarCaja(rutaId: ruta.id, monto: monto, organizacionId: ruta.organizacionId)
            cajaHoy = monto
            mostrarAsignarCaja = false
        } catch {
            errorMessage = "No se pudo guardar la caja: \(error.localizedDescription)"
        }
    }

    func asignarCobrador(cobradorId: UUID?) async {
        do {
            try await rutaService.asignarCobrador(rutaId: ruta.id, cobradorId: cobradorId)
            ruta = Ruta(
                id: ruta.id,
                nombre: ruta.nombre,
                cobradorId: cobradorId,
                activo: ruta.activo,
                organizacionId: ruta.organizacionId,
                createdAt: ruta.createdAt
            )
            cobrador = usuarios.first { $0.id == cobradorId }
            mostrarAsignarCobrador = false
        } catch {
            errorMessage = "No se pudo asignar el cobrador: \(error.localizedDescription)"
        }
    }

    func quitarCobrador() async {
        await asignarCobrador(cobradorId: nil)
    }

    func quitarClienteDeRuta(cliente: Cliente) async {
        guard let clienteId = cliente.id else { return }
        do {
            try await rutaService.quitarClienteDeRuta(clienteId: clienteId)
            clientes.removeAll { $0.id == clienteId }
        } catch {
            errorMessage = "No se pudo quitar el cliente: \(error.localizedDescription)"
        }
    }

    func moverCliente(cliente: Cliente, aRutaId: UUID) async {
        guard let clienteId = cliente.id else { return }
        do {
            try await rutaService.asignarClienteARuta(clienteId: clienteId, rutaId: aRutaId)
            clientes.removeAll { $0.id == clienteId }
            mostrarConfirmacionMover = nil
        } catch {
            errorMessage = "No se pudo mover el cliente: \(error.localizedDescription)"
        }
    }
}
