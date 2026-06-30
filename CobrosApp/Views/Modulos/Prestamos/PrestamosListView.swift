//
//  PrestamosListView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 22/05/26.
//

import SwiftUI

struct PrestamosListView: View {
    @Binding var path: NavigationPath
    @State private var viewModel = PrestamoViewModel()
    @State private var textoBusqueda = ""

    var body: some View {
        Group {
            if let error = viewModel.errorMessage {
                ContentUnavailableView {
                    Label(
                        "Error de conexion",
                        systemImage: "exclamationmark.triangle"
                    )
                } description: {
                    Text(error)
                } actions: {
                    Button("Reintentar") {
                        Task { await viewModel.fetchPrestamos() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.isLoading && viewModel.prestamos.isEmpty {
                ProgressView("Cargando historial de prestamos...")
            } else if viewModel.prestamos.isEmpty {
                ContentUnavailableView(
                    "No hay préstamos",
                    systemImage: "doc.plaintext",
                    description: Text(
                        "Los préstamos que registres aparecerán en está lista."
                    )
                )
            } else {
                List(viewModel.prestamosFiltrados) { prestamo in
                    PrestamoRowView(prestamo: prestamo)
                }
                .refreshable {
                    await viewModel.fetchPrestamos()
                }
            }
        }
        .navigationTitle("Prestamos")
        .searchable(text: $viewModel.textoBusqueda, prompt: "Buscar cliente...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    path.append(HomeDestination.crearPrestamo(nil))
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task(id: viewModel.prestamos.isEmpty) {
            if viewModel.prestamos.isEmpty {
                await viewModel.fetchPrestamos()
            }
        }
    }
}

struct PrestamoRowView: View {
    let prestamo: Prestamo

    private var uiDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "banknote")
                        .font(.title2)
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 4) {
                        if let cliente = prestamo.cliente {
                            Text("\(cliente.nombre) \(cliente.appaterno)")
                                .font(.headline)
                        }

                        Text(
                            "Fecha: \(prestamo.fechaPrestamo, formatter: uiDateFormatter)"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Text("Numero de cuotas: \(prestamo.cuotas)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(
                            "Prestado: $\(prestamo.montoPrestado, specifier: "%.0f")"
                        )
                        .font(.body)
                        .bold()
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .frame(width: geometry.size.width * 0.66, alignment: .leading)

                Divider()
                    .padding(.vertical, 2)

                VStack(spacing: 4) {
                    Image(
                        systemName: prestamo.activo
                            ? "checkmark.circle.fill" : "archivebox.fill"
                    )
                    .font(.title3)
                    .foregroundStyle(prestamo.activo ? .blue : .gray)

                    Text(prestamo.activo ? "Activo" : "Liquidado")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(prestamo.activo ? .blue : .gray)
                }
                .frame(width: geometry.size.width * 0.33)
            }
        }
        .frame(height: 100)
    }
}

#Preview {
    NavigationStack {
        PrestamosListView(path: .constant(NavigationPath()))
    }
}
