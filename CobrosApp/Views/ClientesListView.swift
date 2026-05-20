//
//  ListClientesView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 19/05/26.
//

import SwiftUI

struct ClientesListView: View {
    @State private var viewModel = ClienteViewModel()
    
    var body: some View {
        List {
            if viewModel.clientesFiltrados.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No hay clientes",
                    systemImage: "person.2.slash",
                    description: Text("Presiona el botón de más para agregar uno nuevo.")
                )
            } else {
                ForEach(viewModel.clientesFiltrados) { cliente in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(cliente.nombre) \(cliente.appaterno) \(cliente.apmaterno ?? "")")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HCenterRow(icon: "phone.fill", text: cliente.telefono)
                        HCenterRow(icon: "mappin.and.ellipse", text: cliente.direccion ?? "")
                        HCenterRow(icon: "envelope", text: cliente.email ?? "")
                    }
                    .padding(.vertical, 4)
                }
            }
        }
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
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
            
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .toolbar {
            Button {
                Task {
                    await agregarClienteDePrueba()
                }
            } label: {
                Image(systemName: "plus")
            }
        }
        .task {
            await viewModel.fetchClientes()
        }
        .refreshable {
            await viewModel.fetchClientes()
        }
    }
    
    // Función rápida para probar que la inserción en Supabase funcione correctamente
        private func agregarClienteDePrueba() async {
            let dePrueba = Cliente(
                id: nil, // Dejar nil para que Supabase autogenere el ID (Identity)
                nombre: "Juan",
                appaterno: "Pérez",
                apmaterno: "López",
                telefono: "5512345678",
                direccion: "Av. Reforma 123, CDMX",
                email: "juan.perez@email.com"
            )
            
            let exito = await viewModel.crearCliente(dePrueba)
            if exito {
                print("¡Cliente de prueba guardado e interfaz actualizada!")
            }
        }
}

private struct HCenterRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.purple)
                .frame(width: 16)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        ClientesListView()
    }
}
