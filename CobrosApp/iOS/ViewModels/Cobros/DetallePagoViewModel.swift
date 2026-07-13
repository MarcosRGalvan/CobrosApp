//
//  DetallePagoViewModel.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 18/06/26.
//

import Foundation

@Observable
@MainActor
class DetallePagoViewModel {
    let pago: Pago
    let cliente: ClienteAnidado?
    
    var montoIngresado: String = ""
    var formaPagoSeleccionada: Int?
    var totalPagosRealizados: Int = 0
    var saldoRestante: Double = 0
    
    var isGuardando = false
    var isRegistrandoVisita = false
    var errorMessage: String?
    var pagoRegistradoExitosamente = false
    var mostrarAlertaUltimoPago = false
    var prestamoFinalizado = false
    var visitaSinPagoRegistrada: Bool
    var pagoActualizadoExitosamente = false

    var isLoadingFormasPago: Bool { formasPagoViewModel.isLoading }
    var formasPago: [FormaPago] { formasPagoViewModel.formasPago.filter { $0.activo }}
    
    var mostrarConfirmacionRevertir = false
    var pagoRevertido = false
    
    var estaVencido: Bool {
        guard let fechaVencimiento = pago.fechaVencimiento else { return false }
        return fechaVencimiento < Calendar.current.startOfDay(for: Date())
    }
    
    var pagoIntereses: Double {
        if yaPagado { return pago.pagoIntereses ?? 0 }
        guard let prestamo = pago.prestamos else { return 0 }
        return ((prestamo.montoPrestado * prestamo.interesPorciento / 100) / Double(prestamo.cuotas))
                .rounded(toPlaces: 2)
    }
    
    var recargos: Double {
        // Si ya está pagado usa el valor guardado en BD
        if yaPagado { return pago.recargos ?? 0 }
        return estaVencido ? (pago.montoPagado * 0.10).rounded(toPlaces: 2) : 0
    }
    
    var abonoCapital: Double {
        if yaPagado { return pago.abonoCapital ?? 0 }
        guard let monto = Double(montoIngresado) else { return 0 }
        return (monto - pagoIntereses - recargos).rounded(toPlaces: 2)
    }
    
    var yaPagado: Bool {
        pago.fechaPago != nil
    }
    
    private let pagoService = PagoService()
    private let formasPagoViewModel = FormasPagoViewModel()
    private let prestamoService = PrestamoService()
    
    init(pago: Pago, cliente: ClienteAnidado?) {
        self.pago = pago
        self.cliente = cliente
        self.visitaSinPagoRegistrada = pago.fechaVisitaSinPago != nil
    }
    
    func cargarDatosIniciales() async {
        await formasPagoViewModel.fetchFormasPago()
        formaPagoSeleccionada = pago.formaPagoId
        
        if yaPagado {
            montoIngresado = String(format: "%.2f", pago.montoPagado)
        } else {
            let total = (pago.montoPagado + recargos).rounded(toPlaces: 2)
            montoIngresado = String(format: "%.2f", total)
        }
        
        do {
            totalPagosRealizados = try await pagoService.totalPagosRealizados(prestamoId: pago.prestamoId)
            
            if let montoPrestado = pago.prestamos?.montoPrestado {
                let capitalPagado = try await pagoService.saldoPendiente(prestamoId: pago.prestamoId)
                saldoRestante = (montoPrestado - capitalPagado).rounded(toPlaces: 2)
            }
        } catch {
            print("Error cargando datos: \(error.localizedDescription)")
        }
    }
    
    func registrarPago() async {
        guard let pagoId = pago.id else {
            errorMessage = "Este pago no tiene un ID válido"
            return
        }
        guard let monto = Double(montoIngresado), monto > 0 else {
            errorMessage = "Ingresa un monto válido"
            return
        }
        guard let formaPagoId = formaPagoSeleccionada else {
            errorMessage = "Selecciona una forma de pago"
            return
        }
        guard monto >= pagoIntereses + recargos else {
            let minimo = (pagoIntereses + recargos).formatted(.currency(code: "MXN"))
            errorMessage = "El monto debe cubrir al menos los intereses\(estaVencido ? " y el recargo" : "") (\(minimo))"
            return
        }

        isGuardando = true
        do {
            try await pagoService.registrarPago(
                pagoId: pagoId,
                monto: monto,
                formaPagoId: formaPagoId,
                abonoCapital: abonoCapital,
                pagoIntereses: pagoIntereses,
                recargos: recargos
            )
            isGuardando = false
            
            if let totalCuotas = pago.prestamos?.cuotas {
                let pagosActualizados = totalPagosRealizados + 1
                if pagosActualizados >= totalCuotas {
                    mostrarAlertaUltimoPago = true
                    return // No marca pagoRegistradoExitosamente todavia, espera confirmación
                }
            }
            pagoRegistradoExitosamente = true
        } catch {
            errorMessage = "No se pudo registrar el pago: \(error.localizedDescription)"
            isGuardando = false
        }
    }
    
    func registrarSinPago() async {
        guard let pagoId = pago.id else { return }
        isRegistrandoVisita = true
        do {
            try await pagoService.marcarSinPago(pagoId: pagoId)
            pagoRegistradoExitosamente = true  // cierra la vista y lo quita del listado
        } catch {
            errorMessage = "No se pudo registrar: \(error.localizedDescription)"
        }
        isRegistrandoVisita = false
    }

    func confirmarFinalizarPrestamo() async {
        do {
            try await prestamoService.finalizarPrestamo(prestamoId: pago.prestamoId)
            prestamoFinalizado = true
        } catch {
            errorMessage = "No se pudo finalizar el préstamo: \(error.localizedDescription)"
        }
        pagoRegistradoExitosamente = true
    }
    
    func continuarSinFinalizar() {
        pagoRegistradoExitosamente = true
    }
    
    func actualizarPago() async {
        guard let pagoId = pago.id else {
            errorMessage = "Este pago no tiene un ID válido"
            return
        }
        guard let monto = Double(montoIngresado), monto > 0 else {
            errorMessage = "Ingresa un monto válido"
            return
        }
        
        guard let formaPagoId = formaPagoSeleccionada else {
            errorMessage = "Selecciona una forma de pago"
            return
        }
        guard monto >= pagoIntereses + recargos else {
            let minimo = (pagoIntereses + recargos).formatted(.currency(code: "MXN"))
            errorMessage = "El monto debe cubrir al menos los intereses\(estaVencido ? " y el recargo" : "") (\(minimo))"
            return
        }
        guard let fechaOriginal = pago.fechaPago else {
            errorMessage = "Este pago no tiene fecha registrada"
            return
        }
        
        isGuardando = true
        do {
            try await pagoService.actualizarPagoExistente(
                pagoId: pagoId,
                fechaPagoOriginal: fechaOriginal,
                monto: monto,
                formaPagoId: formaPagoId,
                abonoCapital: abonoCapital,
                abonoIntereses: abonoCapital,
                recargos: recargos,
                cobradorIdOriginal: pago.cobradorId?.uuidString ?? ""
            )
            isGuardando = false
            pagoActualizadoExitosamente = true
        } catch {
            errorMessage = "No se pudo actualizar el pago: \(error.localizedDescription)"
            isGuardando = false
        }
    }
    
    func revertirPago() async {
        guard let pagoId = pago.id else {
            //print("✅ Pago revertido exitosamente")
            return
        }
        //print("🔄 Intentando revertir pago id: \(pagoId)")
        isGuardando = true
        do {
            try await pagoService.revertirPago(pagoId: pagoId)
            //print("✅ Pago revertido exitosamente")
            pagoRevertido = true
        } catch {
            //print("❌ Error al revertir: \(error)")
            errorMessage = "No se pudo revertir el pago: \(error.localizedDescription)"
            isGuardando = false
        }
    }
}
