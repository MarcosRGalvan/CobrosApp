//
//  DetallePagoView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 02/06/26.
//

import SwiftUI

struct DetallePagoView: View {
    @State private var viewModel: DetallePagoViewModel
    @State private var mostrarHistorial = false
    @State private var mostrarConfirmacionSinPago = false
    @Environment(\.dismiss) private var dismiss
    
    init(pago: Pago, cliente: ClienteAnidado?) {
        _viewModel = State(initialValue: DetallePagoViewModel(pago: pago, cliente: cliente))
    }

    private var textoBotonSinPago: String {
        viewModel.visitaSinPagoRegistrada ? "Visita registrada" : "Cliente no pago"
    }

    private var colorTextoBotonSinPago: Color {
        viewModel.visitaSinPagoRegistrada ? .secondary : .red
    }

    private var colorTintBotonSinPago: Color {
        viewModel.visitaSinPagoRegistrada ? .gray : .red
    }

    var body: some View {
        Form {
            Section(header: Text("Datos del Cliente")) {
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("\(viewModel.cliente?.nombre ?? "") \(viewModel.cliente?.appaterno ?? "") \(viewModel.cliente?.apmaterno ?? "")")
                            .font(.title2)
                            .bold()
                    } icon: {
                        Image(systemName: "person.crop.circle.fill")
                    }
                    
                    if let direccion = viewModel.cliente?.direccion, !direccion.isEmpty {
                        Label {
                            Text(direccion)
                        } icon: {
                            Image(systemName: "mappin.and.ellipse")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    if let telefono = viewModel.cliente?.telefono, !telefono.isEmpty {
                        Label {
                            Text(telefono)
                        } icon: {
                            Image(systemName: "phone.fill")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    if let email = viewModel.cliente?.email, !email.isEmpty {
                        Label {
                            Text(email)
                        } icon: {
                            Image(systemName: "envelope.fill")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section(header: Text("Detalles del Pago")) {
                if let totalCuotas = viewModel.pago.prestamos?.cuotas {
                    Label {
                        Text("Pagos realizados: \(viewModel.totalPagosRealizados) de \(totalCuotas)")
                    } icon: {
                        Image(systemName: "checkmark.gobackward")
                            .foregroundStyle(.cyan)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                Label {
                    Text("Saldo restante: \(viewModel.saldoRestante, format: .currency(code: "MXN"))")
                } icon: {
                    Image(systemName: "creditcard.and.123")
                        .foregroundStyle(.cyan)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                    
                Label {
                    Text("Total Pago: \(viewModel.pago.montoPagado, format: .currency(code: "MXN"))")
                } icon: {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(.yellow)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                    
                if viewModel.isLoadingFormasPago {
                    ProgressView("Cargando formas de pago...")
                } else {
                    HStack {
                        Label("", systemImage: "creditcard.fill")
                        Picker("Forma de Pago", selection: $viewModel.formaPagoSeleccionada) {
                            Text("Selecciona").tag(Int?.none)
                            ForEach(viewModel.formasPago) { forma in
                                Text(forma.descripcion).tag(forma.id)
                            }
                        }
                        .disabled(viewModel.yaPagado)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                    
                VStack(spacing: 16) {
                    TextField("$0.00", text: $viewModel.montoIngresado)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .bold()
                        .disabled(viewModel.yaPagado)
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text("Intereses:")
                            Spacer()
                            Text(viewModel.pagoIntereses, format: .currency(code: "MXN"))
                        }
                        if viewModel.estaVencido {
                            HStack {
                                Text("Recargo (10%):")
                                    .foregroundStyle(.red)
                                Spacer()
                                Text(viewModel.recargos, format: .currency(code: "MXN"))
                                    .foregroundStyle(.red)
                            }
                        }
                        HStack {
                            Text("Abono a capital:")
                            Spacer()
                            Text(viewModel.abonoCapital, format: .currency(code: "MXN"))
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                        
                    Button {
                        Task { await viewModel.registrarPago() }
                    } label: {
                        if viewModel.isGuardando {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text(viewModel.yaPagado ? "Pago Registrado" : "Registrar Pago")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isGuardando || viewModel.yaPagado)
                    .tint(viewModel.yaPagado ? .gray : .blue)
                    
                    HStack {
                        Button {
                            mostrarHistorial = true
                        } label: {
                            Text("Historial de pagos")
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                        
                        Button {
                            mostrarConfirmacionSinPago = true
                        } label: {
                            if viewModel.isRegistrandoVisita {
                                ProgressView()
                            } else {
                                Text(textoBotonSinPago)
                                    .foregroundStyle(colorTextoBotonSinPago)
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(colorTintBotonSinPago)
                        .disabled(viewModel.yaPagado || viewModel.visitaSinPagoRegistrada || viewModel.isRegistrandoVisita)
                    }
                }
            }
        }
        .navigationTitle("Detalle del Pago")
        .sheet(isPresented: $mostrarHistorial) {
            NavigationStack {
                HistorialPagosView(
                    prestamoId: viewModel.pago.prestamoId,
                    nombreCliente: viewModel.cliente?.nombre ?? ""
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cerrar") { mostrarHistorial = false }
                    }
                }
            }
        }
        .task { await viewModel.cargarDatosIniciales() }
        .onChange(of: viewModel.pagoRegistradoExitosamente) { _, exitoso in
            if exitoso { dismiss() }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert(
            "Ultimo pago registrado",
            isPresented: Binding(
                get: { viewModel.mostrarAlertaUltimoPago },
                set: { viewModel.mostrarAlertaUltimoPago = $0 }
            )
        ){
            Button("Si, finalizar credito") {
                Task { await viewModel.confirmarFinalizarPrestamo() }
            }
            Button("No, dejarlo activo", role: .cancel) {
                viewModel.continuarSinFinalizar()
            }
        } message: {
            Text("Este es el último pago del credito. ¿Deseas darlo por finalizado?")
        }
        .alert(
            "Cliente no pagó",
            isPresented: $mostrarConfirmacionSinPago
        ) {
            Button("Confirmar", role: .destructive) {
                Task { await viewModel.registrarVisitaSinPago() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("¿Confirmas que visitaste al cliente hoy y no realizó su pago?")
        }
    }
}

#Preview {
    DetallePagoView(
        pago: Pago(id: 45, prestamoId: 22, fechaPago: nil, montoPagado: 500, abonoCapital: 0, pagoIntereses: 0, recargos: 0, numeroCuota: 3, fechaVencimiento: nil, referenciaPago: "", formaPagoId: nil, prestamos: nil, organizacionId: nil, fechaVisitaSinPago: nil),
            
            cliente: ClienteAnidado(nombre: "Marco", appaterno: "Ramirez", apmaterno: "Galvan", telefono: "4353453454", direccion: "Calle Falsa 123", email: "marco@email.com")
        )
}
