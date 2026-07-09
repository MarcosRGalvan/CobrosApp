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
    
    private var pagosRealizados: [Pago] {
        viewModel.pagos.filter { $0.estado == .pagado }
    }
    
    private var pagosNoRealizados: [Pago] {
        viewModel.pagos.filter { $0.estado == .sinPagar }
    }
    
    private var pagosPendientes: [Pago] {
        viewModel.pagos.filter { $0.estado == .pendiente }
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Cargando historial...")
            } else if viewModel.pagos.isEmpty {
                ContentUnavailableView(
                    "Sin historial",
                    systemImage: "list.bullet.clipboard",
                    description: Text("No hay pagos registrados para este préstamo.")
                )
            } else {
                List {
                    Section {
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                Text("\(pagosRealizados.count)")
                                    .font(.title)
                                    .bold()
                                    .foregroundStyle(.green)
                                Text("Realizados")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                            
                            VStack(spacing: 4) {
                                Text("\(pagosNoRealizados.count)")
                                    .font(.title)
                                    .bold()
                                    .foregroundStyle(.red)
                                Text("No realizados")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                            
                            VStack(spacing: 4) {
                                Text("\(viewModel.pagos.count)")
                                    .font(.title)
                                    .bold()
                                Text("Total")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Pagados
                    if !pagosRealizados.isEmpty {
                        Section(header: Text("Pagos realizados")) {
                            ForEach(pagosRealizados) { pago in
                                filaPago(pago)
                            }
                        }
                    }
                    
                    // No realizados
                    if !pagosNoRealizados.isEmpty {
                        Section(header:
                                    Label("No realizados", systemImage: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                        ) {
                            ForEach(pagosNoRealizados) { pago in
                                filaPago(pago)
                            }
                        }
                    }
                    
                    // Pendientes
                    /* if !pagosPendientes.isEmpty {
                        Section(header:
                                    Label("Pendientes", systemImage: "clock.fill")
                                        .foregroundStyle(.orange)
                        ) {
                            ForEach(pagosPendientes) { pago in
                                filaPago(pago)
                            }
                        }
                    } */
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
    
    @ViewBuilder
    private func filaPago(_ pago: Pago) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor(pago).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: iconNombre(pago))
                    .foregroundStyle(iconColor(pago))
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
                        .foregroundStyle(.secondary)
                }
                if let fechaVisita = pago.fechaVisitaSinPago {
                    Text("Visitado sin pago: \(fechaVisita, formatter: uiDateFormatter)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(pago.montoPagado, format: .currency(code: "MXN"))
                    .font(.subheadline)
                    .bold()
                
                // Etiqueta tardío
                if let fechaPago = pago.fechaPago,
                   let fechaVence = pago.fechaVencimiento {
                    let cal = Calendar.current
                    if cal.startOfDay(for: fechaPago) > cal.startOfDay(for: fechaVence) {
                        Text("Tardío")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                // Etiqueta no pagó
                if pago.estado == .sinPagar {
                    Text("No pagó")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconNombre(_ pago: Pago) -> String {
        switch pago.estado {
        case .pagado: return "checkmark.circle.fill"
        case .sinPagar: return "xmark.circle.fill"
        default: return "clock.fill"
        }
    }
    
    private func iconColor(_ pago: Pago) -> Color {
        switch pago.estado {
        case .pagado: return .green
        case .sinPagar: return .red
        default: return .orange
        }
    }
}

#Preview {
    NavigationStack {
        HistorialPagosView(prestamoId: 36, nombreCliente: "Marco Ramirez")
    }
}
