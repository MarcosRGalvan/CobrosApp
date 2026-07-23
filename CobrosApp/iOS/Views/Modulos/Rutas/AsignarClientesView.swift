//
//  AsignarClientesView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 21/07/26.
//

import SwiftUI

struct AsignarClientesView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: DetalleRutaViewModel
    @State private var clientesSinRuta: [Cliente] = []
    @State private var isLoading = false
    @State private var textoBusqueda = ""
    
    private let rutaService = RutaService()
    
    private var clientesFiltrados: [Cliente] {
        if textoBusqueda.isEmpty { return clientesSinRuta }
        return clientesSinRuta.filter {
            "\($0.nombre) \($0.appaterno)".lowercased().contains(textoBusqueda.lowercased())
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Cargando clientes...")
                } else if clientesFiltrados.isEmpty {
                    ContentUnavailableView(
                        "Sin clientes disponibles",
                        systemImage: "person.slash.fill",
                        description: Text("No hay clientes sin ruta asignada.")
                    )
                } else {
                    List(clientesFiltrados) { cliente in
                        Button {
                            Task { await asignarCliente(cliente) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(cliente.nombre) \(cliente.appaterno)")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    if let dir = cliente.direccion, !dir.isEmpty {
                                        Text(dir)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(cliente.telefono)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Agregar Clientes")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $textoBusqueda, prompt: "Buscar cliente...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task { await cargarClientesSinRuta() }
        }
    }
    
    private func cargarClientesSinRuta() async {
        isLoading = true
        do {
            clientesSinRuta = try await rutaService.fetchClientesSinRuta()
        } catch {
            viewModel.errorMessage = "No se pudieron cargar los clientes: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func asignarCliente(_ cliente: Cliente) async {
        guard let clienteId = cliente.id else { return }
        do {
            try await rutaService.asignarClienteARuta(
                clienteId: clienteId,
                rutaId: viewModel.ruta.id
            )
            clientesSinRuta.removeAll { $0.id == clienteId }
            viewModel.clientes.append(cliente)
        } catch {
            viewModel.errorMessage = "No se puede asignar el cliente: \(error.localizedDescription)"
        }
    }
}
