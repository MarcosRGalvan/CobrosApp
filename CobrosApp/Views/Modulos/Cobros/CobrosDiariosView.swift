//
//  CobrosDiariosView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/05/26.
//

import SwiftUI

struct CobrosDiariosView: View {
    @State private var viewModel = CobrosDiariosViewModel()
    @State private var pagoSeleccionado: Pago? = nil

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
            } else if viewModel.cobrosAtrasados.isEmpty && viewModel.cobrosDeHoy.isEmpty {
                ContentUnavailableView.search(text: viewModel.textoBusqueda)
            } else {
                listaDeCobros
            }
        }
        .navigationTitle("Cobros Pendientes")
        .searchable(text: $viewModel.textoBusqueda, prompt: "Buscar cliente...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(isOn: $viewModel.mostrarSoloPendientes) {
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
    
    // Extraído del body para ayudar al type-checker
    private var listaDeCobros: some View {
        List {
            if !viewModel.cobrosDeHoy.isEmpty {
                seccionCobros(titulo: "Vencen hoy", pagos: viewModel.cobrosDeHoy, esAtrasados: false)
            }
            if !viewModel.cobrosAtrasados.isEmpty {
                seccionCobros(titulo: "Atrasados", pagos: viewModel.cobrosAtrasados, esAtrasados: true)
            }
        }
        .navigationDestination(item: $pagoSeleccionado) { pago in
            DetallePagoView(pago: pago, cliente: pago.prestamos?.clientes)
        }
    }
    
    @ViewBuilder
    private func seccionCobros(titulo: String, pagos: [Pago], esAtrasados: Bool) -> some View {
        Section {
            ForEach(pagos) { pago in
                Button {
                    pagoSeleccionado = pago
                } label: {
                    CobroDiarioRow(pago: pago)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
            }
        } header: {
            if esAtrasados {
                Label(titulo, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } else {
                Text(titulo)
            }
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
    
    private var diasAtraso: Int? {
        guard let vencimiento = pago.fechaVencimiento, pago.fechaPago == nil else { return nil }
        let hoy = Calendar.current.startOfDay(for: Date())
        let dias = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: vencimiento), to: hoy).day ?? 0
        return dias > 0 ? dias : nil
    }

    var body: some View {
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
                    if let dias = diasAtraso {
                        Text("\(dias) día\(dias == 1 ? "" : "s") de atraso")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.red)
                    }
                    Text("Total pago: \(pago.montoPagado, format: .currency(code: "MXN"))")
                        .font(.body)
                        .bold()
                        .foregroundStyle(.green)
                }
            }
            .padding(.vertical, 4)
            .padding(.leading, 15)
            .frame(maxWidth: .infinity, alignment: .leading)

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
            .frame(width: 90)
            .frame(maxHeight: .infinity)
            .background(yaCobrado ? Color.green : Color.red)
        }
        .frame(height: 110)
    }
}

#Preview {
    CobrosDiariosView()
}
