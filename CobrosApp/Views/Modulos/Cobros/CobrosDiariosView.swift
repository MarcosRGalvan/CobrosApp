//
//  CobrosDiariosView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/05/26.
//

import SwiftUI

struct CobrosDiariosView: View {
    @State private var viewModel = CobrosDiariosViewModel()
    @State private var mostrarSoloPendientes = false
    @State private var pagoSeleccionado: Pago? = nil
    
    private var cobrosFiltrados: [Pago] {
        mostrarSoloPendientes
        ? viewModel.cobros.filter { $0.fechaPago == nil }
        : viewModel.cobros
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Cargando cobros de hoy...")
            } else if viewModel.cobros.isEmpty {
                ContentUnavailableView(
                    "Sin cobros pendientes",
                    systemImage: "checkmark.seal.fill",
                    description: Text("No hay pagos que vencen hoy.")
                )
            } else {
                List {
                    ForEach(cobrosFiltrados) { pago in
                        Button {
                            pagoSeleccionado = pago
                        } label: {
                            CobroDiarioRow(pago: pago)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                    }
                }
                .navigationDestination(item: $pagoSeleccionado) { pago in
                    DetallePagoView()
                }
            }
        }
        .navigationTitle("Cobros de Hoy")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(isOn: $mostrarSoloPendientes) {
                    Text("Solo Pendientes")
                        .font(.caption)
                }
                .toggleStyle(.switch)
            }
        }
        .onAppear { viewModel.cargarCobrosDeHoy() }
        .refreshable { viewModel.cargarCobrosDeHoy() }
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

struct CobroDiarioRow: View {
    let pago: Pago
    
    private var yaCobrado: Bool {
        pago.fechaPago != nil
    }
    
    private var uiDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title)
                        .foregroundStyle(.yellow)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pago.nombreCliente)
                            .font(.title3)
                            .bold()
                        if let cuota = pago.numeroCuota {
                            Text("Pago:\(cuota)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let fecha = pago.fechaVencimiento {
                            Text("Fecha vence: \(fecha, formatter: uiDateFormatter)")
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(.orange)
                        }
                        
                        Spacer()
                        
                        Text("Total pago: \(pago.montoPagado, format: .currency(code: "MXN"))")
                            .font(.body)
                            .bold()
                            .foregroundStyle(.green)
                    }
                }
                .padding(.vertical, 4)
                .padding(.leading, 15)
                .frame(width: geometry.size.width * 0.70, alignment: .leading)
                
                Divider()
                
                VStack(spacing: 4) {
                    if yaCobrado {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                            .font(.title3)
                        Text("Pagado")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                            .font(.title3)
                        Text("Sin pago")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: geometry.size.width * 0.33, height: geometry.size.height * 1, alignment: .center)
                .background(yaCobrado ? Color.green : Color.red)
            }
        }
        .frame(height: 110)
    }
}

#Preview {
    CobrosDiariosView()
}
