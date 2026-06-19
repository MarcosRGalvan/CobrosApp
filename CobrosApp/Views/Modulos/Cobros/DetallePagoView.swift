//
//  DetallePagoView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 02/06/26.
//

import SwiftUI

struct DetallePagoView: View {
    @State private var viewModel: DetallePagoViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(pago: Pago, cliente: ClienteAnidado?) {
        _viewModel = State(initialValue: DetallePagoViewModel(pago: pago, cliente: cliente))
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
                if let numPago = viewModel.pago.numeroCuota {
                    Label {
                        Text("Pago número: \(numPago)")
                    } icon: {
                        Image(systemName: "number.square.fill")
                            .foregroundStyle(.cyan)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                Label {
                    Text("Número de Prestamo: \(viewModel.pago.prestamoId)")
                } icon: {
                    Image(systemName: "numbers.rectangle.fill")
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
                            Text("Registrar Pago").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isGuardando)
                    
                    HStack {
                        Button {
                            
                        } label: {
                            Text("Historial de pagos")
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                        
                        Button {
                            
                        } label: {
                            Text("Cliente no pago")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
            }
        }
        .navigationTitle("Detalle del Pago")
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
    }
}

#Preview {
    DetallePagoView(
            pago: Pago(id: 45, prestamoId: 22, fechaPago: nil, montoPagado: 500, abonoCapital: 0, pagoIntereses: 0, recargos: 0, numeroCuota: 3, fechaVencimiento: nil, referenciaPago: "", formaPagoId: nil, prestamos: nil),
            
            cliente: ClienteAnidado(nombre: "Marco", appaterno: "Ramirez", apmaterno: "Galvan", telefono: "4353453454", direccion: "Calle Falsa 123", email: "marco@email.com")
        )
}
