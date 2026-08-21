//
//  DetalleRutaView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 21/07/26.
//

import SwiftUI

struct DetalleRutaView: View {
    @State private var viewModel: DetalleRutaViewModel
    @Environment(AuthViewModel.self) private var auth
    
    private var degradado: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppPrimary").opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    init(ruta: Ruta) {
        _viewModel = State(initialValue: DetalleRutaViewModel(ruta: ruta))
    }
    var body: some View {
        ZStack(alignment: .top) {
            
            Group {
                if viewModel.isLoading {
                    ProgressView("Cargando...")
                } else {
                    List {
                        // Seccion cobrador
                        Section(header: Text("Cobrador asignado")) {
                            if let cobrador = viewModel.cobrador {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cobrador.nombre)
                                            .font(.headline)
                                        if let tel = cobrador.telefono, !tel.isEmpty {
                                            Text(tel)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if auth.esAdmin {
                                        Button {
                                            Task { await viewModel.quitarCobrador() }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.orange)
                                    Text("Sin cobrador asignado")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            if auth.esAdmin {
                                Button {
                                    viewModel.mostrarAsignarCobrador = true
                                } label: {
                                    Label(
                                        viewModel.cobrador == nil ? "Asignar cobrador" : "Cambiar cobrador",
                                        systemImage: "person.badge.plus"
                                    )
                                }
                            }
                        }
                        
                        // Seccion clientes
                        Section(header:
                                    HStack {
                            Text("Clientes (\(viewModel.clientes.count))")
                            Spacer()
                            if auth.esAdmin {
                                Button {
                                    viewModel.mostrarAsignarClientes = true
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                        ) {
                            if viewModel.clientes.isEmpty {
                                Text("Sin clientes en está ruta")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(viewModel.clientes) { cliente in
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.fill")
                                            .foregroundStyle(.blue)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(cliente.nombre) \(cliente.appaterno)")
                                                .font(.headline)
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
                                    .padding(.vertical, 2)
                                    .swipeActions(edge: .trailing) {
                                        if auth.esAdmin {
                                            Button(role: .destructive) {
                                                Task { await viewModel.quitarClienteDeRuta(cliente: cliente) }
                                            } label: {
                                                Label("Quitar", systemImage: "minus.circle")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .refreshable { await viewModel.cargarDatos() }
                }
            }
        }
        //.scrollContentBackground(.hidden)
        .navigationTitle(viewModel.ruta.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.cargarDatos() }
        .sheet(isPresented: $viewModel.mostrarAsignarCobrador) {
            AsignarCobradorView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.mostrarAsignarClientes) {
            AsignarClientesView(viewModel: viewModel)
        }
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
    NavigationStack {
        DetalleRutaView(
            ruta: Ruta(
                id: UUID(),
                nombre: "Ruta Norte",
                cobradorId: nil,
                activo: true,
                organizacionId: UUID(),
                createdAt: Date()
            )
        )
        .environment(AuthViewModel())
    }
}
