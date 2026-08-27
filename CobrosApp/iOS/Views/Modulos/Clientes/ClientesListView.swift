//
//  ListClientesView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 19/05/26.
//

import SwiftUI

enum ClienteDestino: Hashable {
    case crearCliente
    case crearPrestamo(Cliente)
    case detalleCliente(Cliente)
}

struct ClientesListView: View {
    @Binding var path: NavigationPath
    @State private var viewModel = ClienteViewModel()
    
    private var degradado: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppPrimary").opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            /*VStack(spacing: 0) {
                degradado
                    .frame(height: UIScreen.main.bounds.height / 2)
                    .ignoresSafeArea(edges: .top)
                Spacer()
            }*/
            
            List {
                if viewModel.clientesFiltrados.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No hay clientes",
                        systemImage: "person.2.slash",
                        description: Text("Presiona el botón de más para agregar uno nuevo.")
                    )
                } else {
                    ForEach(viewModel.clientesFiltrados) { cliente in
                        NavigationLink(value: ClienteDestino.detalleCliente(cliente)) {
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(RiesgoCrediticio(score: cliente.id.flatMap { viewModel.scores[$0] }).color)
                                    .frame(width: 10, height: 10)
                                    .padding(.top, 6)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(nombreCompleto(cliente))
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    HCenterRow(icon: "phone.fill", text: cliente.telefono)
                                    HCenterRow(icon: "mappin.and.ellipse", text: cliente.direccion ?? "")
                                    HCenterRow(icon: "envelope", text: cliente.email ?? "")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            //.scrollContentBackground(.hidden)
            .navigationTitle("Clientes")
            .searchable(text: $viewModel.textoBusqueda, prompt: "Buscar por nombre o teléfono")
            .overlay {
                if viewModel.isLoading && viewModel.clientes.isEmpty {
                    ProgressView("Conectando con el servidor...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .alert("Error", isPresented: mostrarError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        path.append(ClienteDestino.crearCliente)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("AppPrimary"))
                }
            }
            .navigationDestination(for: ClienteDestino.self) { destino in
                switch destino {
                case .crearCliente:
                    CrearClienteView(viewModel: viewModel) { clienteCreado in
                        Task { @MainActor in
                            path.append(ClienteDestino.crearPrestamo(clienteCreado))
                        }
                    }
                case .crearPrestamo(let cliente):
                    CreatePrestamoView(
                        viewModel: PrestamoViewModel(),
                        clientePreseleccionado: cliente
                    ) {
                        path = NavigationPath()
                        path.append(HomeDestination.prestamos)
                    }
                case .detalleCliente(let cliente):
                    DetalleClienteView(cliente: cliente)
                }
            }
            .task {
                await viewModel.fetchClientes()
            }
            .refreshable {
                await viewModel.fetchClientes()
            }
        }
    }
    
    private var mostrarError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )
    }
    
    private func nombreCompleto(_ cliente: Cliente) -> String {
        [cliente.nombre, cliente.appaterno, cliente.apmaterno]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

private struct HCenterRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.mint)
                .frame(width: 16)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var path = NavigationPath()
        
        @State private var viewModel: ClienteViewModel = {
            let vm = ClienteViewModel()
            vm.clientes = Cliente.listaMock
            return vm
        }()
        
        var body: some View {
            NavigationStack(path: $path) {
                ClientesListView(path: $path)
            }
        }
    }
    return PreviewWrapper()
}
