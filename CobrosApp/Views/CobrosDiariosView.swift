//
//  CobrosDiariosView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/05/26.
//

import SwiftUI

struct CobrosDiariosView: View {
    @State private var viewModel = CobrosDiariosViewModel()

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
                    ForEach(viewModel.cobros) { pago in
                        CobroDiarioRow(pago: pago) {
                            Task {
                                await viewModel.marcarComoPagado(pago: pago)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Cobros de Hoy")
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
    let onCobrar: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pago.nombreCliente)
                    .font(.title3)
                    .bold()
                if let cuota = pago.numeroCuota {
                    Text("Pago: \(cuota)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let fecha = pago.fechaVencimiento {
                    Text(fecha, style: .date)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(pago.montoPagado, format: .currency(code: "MXN"))
                    .font(.headline)
                    .foregroundStyle(.green)
                Button("Cobrar", action: onCobrar)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CobrosDiariosView()
}
