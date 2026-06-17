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
                VStack(alignment: .leading, spacing: 12) {
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
                }
            }
        }
        .navigationTitle("Detalle del Pago")
    }
}

#Preview {
    DetallePagoView(
            pago: Pago(id: 45, prestamoId: 22, fechaPago: nil, montoPagado: 500, abonoCapital: 0, pagoIntereses: 0, recargos: 0, numeroCuota: 3, fechaVencimiento: nil, referenciaPago: "", formaPagoId: nil, vencido: false, prestamos: nil),
            
            cliente: ClienteAnidado(nombre: "Marco", appaterno: "Ramirez", apmaterno: "Galvan", telefono: "4353453454", direccion: "Calle Falsa 123", email: "marco@email.com")
        )
}
