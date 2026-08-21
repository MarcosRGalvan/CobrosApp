//
//  UsuariosListView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 26/06/26.
//

import SwiftUI

struct UsuariosListView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var viewModel = UsuariosViewModel()
    @State private var mostrarCrearCobrador = false
    
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
            
            Group {
                if viewModel.isLoading {
                    ProgressView("Cargando usuarios...")
                } else if viewModel.usuarios.isEmpty {
                    ContentUnavailableView(
                        "Sin cobradores",
                        systemImage: "person.slash.fill",
                        description: Text("Aún no has dado de alta cobradores.")
                    )
                } else {
                    List {
                        ForEach(viewModel.usuariosFiltrados) { usuario in
                            NavigationLink {
                                DetalleUsuarioView(usuario: usuario)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(usuario.activo ? Color("AppPrimary") : .gray)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(usuario.nombre)
                                            .font(.headline)
                                            .foregroundStyle(usuario.activo ? .primary : .secondary)
                                        if let telefono = usuario.telefono, !telefono.isEmpty {
                                            Text(telefono)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        if !usuario.activo {
                                            Text("Deshabilitado")
                                                .font(.caption)
                                                .foregroundStyle(.red)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: usuario.activo ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(usuario.activo ? .green : .red)
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    Task { await viewModel.toggleActivo(usuario: usuario) }
                                } label: {
                                    Label(
                                        usuario.activo ? "Deshabilitar" : "Habilitar",
                                        systemImage: usuario.activo ? "person.slash.fill" : "person.fill.checkmark"
                                    )
                                }
                                .tint(usuario.activo ? .red : .green)
                            }
                        }
                    }
                }
            }
        }
        //.scrollContentBackground(.hidden)
        .navigationTitle("Cobradores")
        .searchable(text: $viewModel.textoBusqueda, prompt: "Buscar cobrador...")
        .toolbar {
            if auth.esAdmin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mostrarCrearCobrador = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("AppPrimary"))
                }
            }
        }
        .sheet(isPresented: $mostrarCrearCobrador) {
            CrearCobradorView()
                .onDisappear {
                    Task { await viewModel.cargarUsuarios() }
                }
        }
        .task { await viewModel.cargarUsuarios() }
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
    UsuariosListView()
        .environment(AuthViewModel())
}
