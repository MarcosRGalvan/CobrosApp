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
    var errorMessage: String?
    var pagoRegistradoExitosamente = false
    
    var isLoadingFormasPago: Bool { formasPagoViewModel.isLoading }
    var formasPago: [FormaPago] { formasPagoViewModel.formasPago.filter { $0.activo }}
    
    var estaVencido: Bool {
        guard let fechaVencimiento = pago.fechaVencimiento else { return false }
        return fechaVencimiento < Calendar.current.startOfDay(for: Date())
    }
    
    var recargos: Double {
        estaVencido ? (pago.montoPagado * 0.10).rounded(toPlaces: 2) : 0
    }
    
    var pagoIntereses: Double {
        guard let prestamo = pago.prestamos else { return 0 }
        return ((prestamo.montoPrestado * prestamo.interesPorciento / 100) / Double(prestamo.cuotas))
            .rounded(toPlaces: 2)
    }
    
    var abonoCapital: Double {
        guard let monto = Double(montoIngresado) else { return 0 }
        return (monto - pagoIntereses - recargos).rounded(toPlaces: 2)
    }
    
    private let pagoService = PagoService()
    private let formasPagoViewModel = FormasPagoViewModel()
    
    init(pago: Pago, cliente: ClienteAnidado?) {
        self.pago = pago
        self.cliente = cliente
    }
    
    func cargarDatosIniciales() async {
        await formasPagoViewModel.fetchFormasPago()
        formaPagoSeleccionada = pago.formaPagoId
        let total = (pago.montoPagado + recargos).rounded(toPlaces: 2)
        montoIngresado = String(format: "%.2f", total)
        
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
            pagoRegistradoExitosamente = true
        } catch {
            errorMessage = "No se pudo registrar el pago: \(error.localizedDescription)"
            isGuardando = false
        }
    }
}
