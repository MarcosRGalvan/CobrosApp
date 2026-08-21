//
//  DetallePrestamoView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 03/07/26.
//

import SwiftUI

struct DetallePrestamoView: View {
    let prestamo: Prestamo
    @State private var mostrarHistorial = false
    
    private var degradado: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppPrimary").opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var uiDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }
    
    private var montoPorCuota: Double {
        guard prestamo.cuotas > 0 else { return 0 }
        let totalConInteres = prestamo.montoPrestado * (1 + prestamo.interesPorciento / 300)
        return totalConInteres / Double(prestamo.cuotas)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
        
            Form {
                Section(header: Text("Cliente")) {
                    Label(prestamo.nombreCompletoCliente, systemImage: "person.crop.circle.fill")
                    
                    if let direccion = prestamo.cliente?.direccion, !direccion.isEmpty {
                        Label(direccion, systemImage: "mappin.and.ellipse")
                    }
                }
                
                Section(header: Text("Datos del préstamo")) {
                    HStack {
                        Text("Monto prestado")
                        Spacer()
                        Text(prestamo.montoPrestado, format: .currency(code: "MXN"))
                            .bold()
                    }
                    HStack {
                        Text("Interés")
                        Spacer()
                        Text("\(prestamo.interesPorciento, specifier: "%.1f")%")
                    }
                    HStack {
                        Text("Número de cuotas")
                        Spacer()
                        Text("\(prestamo.cuotas)")
                    }
                    HStack {
                        Text("Pago por cuota (aprox.)")
                        Spacer()
                        Text(montoPorCuota, format: .currency(code: "MXN"))
                    }
                    HStack {
                        Text("Fecha de inicio")
                        Spacer()
                        Text(prestamo.fechaPrestamo, formatter: uiDateFormatter)
                    }
                    if let fechaTermino = prestamo.fechaTermino {
                        HStack {
                            Text("Fecha de término")
                            Spacer()
                            Text(fechaTermino, formatter: uiDateFormatter)
                        }
                    }
                }
                
                Section(header: Text("Estado")) {
                    Label {
                        Text(prestamo.activo ? "Activo" : "Liquidado")
                            .foregroundStyle(prestamo.activo ? .primary : .secondary)
                    } icon: {
                        Image(systemName: prestamo.activo ? "checkmark.circle.fill" : "archivebox.fill")
                            .foregroundStyle(prestamo.activo ? .green : .gray)
                    }
                }
                
                Section {
                    Button {
                        mostrarHistorial = true
                    } label: {
                        Label("Ver historial de pago", systemImage: "clock.arrow.circlepath")
                    }
                }
            }
        }
        //.scrollContentBackground(.hidden)
        .navigationTitle("Detalle del Préstamo")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $mostrarHistorial) {
            NavigationStack {
                HistorialPagosView(
                    prestamoId: prestamo.id ?? 0,
                    nombreCliente: prestamo.nombreCompletoCliente
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cerrar") { mostrarHistorial = false }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DetallePrestamoView(
            prestamo: Prestamo(
                id: 22,
                clienteId: 5,
                montoPrestado: 5000,
                cuotas: 10,
                fechaPrestamo: Date(),
                frecuenciaPago: 7,
                interesPorciento: 15,
                fechaTermino: Date().addingTimeInterval(60 * 60 * 24 * 70),
                activo: false,
                organizacionId: nil,
                cliente: ClienteAnidado(
                    nombre: "Marco",
                    appaterno: "Ramirez",
                    apmaterno: "Galvan",
                    telefono: "4353453454",
                    direccion: "Calle Falsa 123",
                    email: "marco@email.com"
                )
            )
        )
    }
}
