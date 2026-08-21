//
//  RutaListView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 17/07/26.
//

import SwiftUI

struct RutaListView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var viewModel = RutaViewModel()
    @State private var rutaSeleccionada: Ruta? = nil
    
    private var degradado: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppPrimary").opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if viewModel.isLoading {
                    ProgressView("Cargando rutas...")
                } else if viewModel.rutas.isEmpty {
                    ContentUnavailableView(
                        "Sin rutas",
                        systemImage: "road.lanes",
                        description: Text("Aún no hay rutas registradas.")
                    )
                } else {
                    List {
                        if !viewModel.rutasActivas.isEmpty {
                            Section(header: Text("Activas")) {
                                ForEach(viewModel.rutasActivas) { ruta in
                                    rutaLink(ruta)
                                }
                            }
                        }
                        
                        if !viewModel.rutasInactivas.isEmpty {
                            Section(header: Text("Inactivas")) {
                                ForEach(viewModel.rutasInactivas) { ruta in
                                    rutaLink(ruta)
                                }
                            }
                        }
                    }
                    .refreshable { await viewModel.cargarRutas() }
                }
            }
        }
        .navigationTitle("Rutas")
        .toolbar {
            if auth.esAdmin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.mostrarCrearRuta = true
                    } label: {
                         Image(systemName: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("AppPrimary"))
                }
            }
        }
        .task { await viewModel.cargarRutas() }
        .sheet(isPresented: $viewModel.mostrarCrearRuta) {
            CrearRutaView(viewModel: viewModel)
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
    
    @ViewBuilder
    private func rutaLink(_ ruta: Ruta) -> some View {
        NavigationLink {
            DetalleRutaView(ruta: ruta)
        } label: {
            RutaRow(
                ruta: ruta,
                totalClientes: viewModel.clientesEnRuta(ruta.id)
            )
        }
        .swipeActions(edge: .trailing) {
            if auth.esAdmin {
                Button {
                    Task { await viewModel.toggleActivo(ruta: ruta) }
                } label: {
                    Label(
                        ruta.activo ? "Deshabilitar" : "Habilitar",
                        systemImage: ruta.activo ? "xmark.circle" : "checkmark.circle"
                    )
                }
                .tint(ruta.activo ? .red : .green)
            }
        }
    }
}

struct RutaRow: View {
    let ruta: Ruta
    let totalClientes: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ruta.activo ? Color("AppPrimary").opacity(0.15) : Color.gray.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "road.lanes.curved.right")
                    .foregroundStyle(ruta.activo ? Color("AppPrimary") : .gray)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ruta.nombre)
                    .font(.headline)
                    .foregroundStyle(ruta.activo ? .primary : .secondary)
                
                HStack(spacing: 8) {
                    Label("\(totalClientes) clientes", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if ruta.cobradorId != nil {
                        Label("Con cobrador", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Label("Sin cobrador", systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            if !ruta.activo {
                Text("Inactiva")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}


#Preview {
    NavigationStack {
        RutaListView()
            .environment(AuthViewModel())
    }
}
