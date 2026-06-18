//
//  DetallePagoView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 02/06/26.
//

import SwiftUI

struct DetallePagoView: View {
    let pago: Pago
    let cliente: ClienteAnidado?
    
    @State private var fp = FormasPagoViewModel()
    @State private var formaPagoSeleccionadaId: Int?
    @State private var montoIngresado: String = ""

    
    var body: some View {
        Form {
            Section(header: Text("Datos del Cliente")) {
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("\(cliente?.nombre ?? "") \(cliente?.appaterno ?? "") \(cliente?.apmaterno ?? "")")
                            .font(.title2)
                            .bold()
                    } icon: {
                        Image(systemName: "person.crop.circle.fill")
                    }
                    
                    if let direccion = cliente?.direccion, !direccion.isEmpty {
                        Label {
                            Text(direccion)
                        } icon: {
                            Image(systemName: "mappin.and.ellipse")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    if let telefono = cliente?.telefono, !telefono.isEmpty {
                        Label {
                            Text(telefono)
                        } icon: {
                            Image(systemName: "phone.fill")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    if let email = cliente?.email, !email.isEmpty {
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
                if let numPago = pago.numeroCuota {
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
                    Text("Número de Prestamo: \(pago.prestamoId)")
                } icon: {
                    Image(systemName: "numbers.rectangle.fill")
                        .foregroundStyle(.cyan)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                    
                Label {
                    Text("Total Pago: \(pago.montoPagado, format: .currency(code: "MXN"))")
                } icon: {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(.yellow)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                    
                if fp.isLoading {
                    ProgressView("Cargando formas de pago...")
                } else {
                    HStack {
                        Label("", systemImage: "creditcard.fill")
                        Picker("Forma de Pago", selection: $formaPagoSeleccionadaId) {
                            Text("Selecciona").tag(Int?.none)
                            ForEach(fp.formasPago.filter { $0.activo }) { forma in
                                Text(forma.descripcion).tag(forma.id)
                            }
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                    
                VStack(spacing: 16) {
                    TextField("$0.00", text: $montoIngresado)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .bold()
                        
                    Button {
                            
                    } label: {
                        Text("Registrar Pago")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
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
        .task {
            await fp.fetchFormasPago()
            formaPagoSeleccionadaId = pago.formaPagoId
        }
    }
}

#Preview {
    DetallePagoView(
            pago: Pago(id: 45, prestamoId: 22, fechaPago: nil, montoPagado: 500, abonoCapital: 0, pagoIntereses: 0, recargos: 0, numeroCuota: 3, fechaVencimiento: nil, referenciaPago: "", formaPagoId: nil, vencido: false, prestamos: nil),
            
            cliente: ClienteAnidado(nombre: "Marco", appaterno: "Ramirez", apmaterno: "Galvan", telefono: "4353453454", direccion: "Calle Falsa 123", email: "marco@email.com")
        )
}
