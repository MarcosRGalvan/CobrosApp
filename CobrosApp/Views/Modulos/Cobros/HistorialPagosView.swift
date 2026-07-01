//
//  HistorialPagosView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/06/26.
//

import SwiftUI

struct HistorialPagosView: View {
    let prestamoId: Int
    let nombreCliente: String
    @State private var viewModel = HistorialPagosViewModel()
    
    private var uiDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Cargando historial...")
            } else if viewModel.pagos.isEmpty {
                ContentUnavailableView(
                    "Sin pagos",
                    systemImage: "list.bullet.clipboard",
                    description: Text("No hay pagos registrados para este préstamo.")
                )
            } else {
                List {
                    ForEach(viewModel.pagos) { pago in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(pago.fechaPago != nil ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: pago.fechaPago != nil ? "checkmark.circle.fill" : "clock.fill")
                                    .foregroundStyle(pago.fechaPago != nil ? .green : .orange)
                                    .font(.title3)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                if let cuota = pago.numeroCuota {
                                    Text("Cuota \(cuota)")
                                        .font(.headline)
                                }
                                if let fechaVence = pago.fechaVencimiento {
                                    Text("Vence: \(fechaVence, formatter: uiDateFormatter)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let fechaPago = pago.fechaPago {
                                    Text("Pagado: \(fechaPago, formatter: uiDateFormatter)")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(pago.montoPagado, format: .currency(code: "MXN"))
                                    .font(.subheadline)
                                    .bold()
                                if let fechaPago = pago.fechaPago,
                                   let fechaVence = pago.fechaVencimiento {
                                    let calendar = Calendar.current
                                    let pagoSinHora = calendar.startOfDay(for: fechaPago)
                                    let venceSinHora = calendar.startOfDay(for: fechaVence)
                                    if pagoSinHora > venceSinHora {
                                        Text("Tardío")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Historial de Pagos")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.cargarHistorial(prestamoId: prestamoId) }
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
    HistorialPagosView(prestamoId: 1, nombreCliente: "Marco Ramirez")
}
