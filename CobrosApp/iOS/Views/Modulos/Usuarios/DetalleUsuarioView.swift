//
//  DetalleUsuarioView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 15/07/26.
//

import SwiftUI

struct DetalleUsuarioView: View {
    let usuario: Usuario
    @State private var viewModel: DetalleUsuarioViewModel
    
    init(usuario: Usuario) {
        self.usuario = usuario
        _viewModel = State(initialValue: DetalleUsuarioViewModel(usuario: usuario))
    }
    
    var body: some View {
        List {
            Section(header: Text("Datos del Cobrador")) {
                Label(usuario.nombre, systemImage: "person.crop.circle.fill")
                    .font(.headline)
                
                if let telefono = usuario.telefono, !telefono.isEmpty {
                    Label(telefono, systemImage: "phone.fill")
                }
                
                if let direccion = usuario.direccion, !direccion.isEmpty {
                    Label(direccion, systemImage: "mappin.and.ellipse")
                }
                
                Label(
                    usuario.rol == .admin ? "Administrador" : "Cobrador",
                    systemImage: usuario.rol == .admin ? "crown.fill" : "bag.fill"
                )
                
                Label(
                    usuario.activo ? "Activo" : "Deshabilitado",
                    systemImage: usuario.activo ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .foregroundStyle(usuario.activo ? .green : .red)
            }
            
            Section(header: Text("Estadísticas")) {
                DatePicker(
                    "Fecha",
                    selection: Binding(
                        get: { viewModel.fechaSeleccionada },
                        set: { nuevaFecha in
                            viewModel.fechaSeleccionada = nuevaFecha
                            Task { await viewModel.cargarEstadisticas() }
                        }
                    ),
                    displayedComponents: .date
                )
                
                if viewModel.isLoading {
                    ProgressView("Cargando estadísticas...")
                } else {
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Text("\(viewModel.totalCobros)")
                                .font(.title)
                                .bold()
                                .foregroundStyle(.blue)
                            Text("Cobros realizados")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider().frame(height: 50)
                        
                        VStack(spacing: 4) {
                            Text("\(viewModel.totalRecaudo, format: .currency(code: "MXN"))")
                                .font(.title3)
                                .bold()
                                .foregroundStyle(.green)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                            Text("Total recaudado")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle(usuario.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: usuario.id) { await viewModel.cargarEstadisticas() }
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
        DetalleUsuarioView(
            usuario: Usuario(
                id: UUID(),
                organizacionId: UUID(),
                nombre: "Heidy Dayana",
                clave: "cobrador1",
                rol: .admin,
                direccion: "Calle Falsa 123",
                telefono: "4353453454",
                activo: false,
                rutaAsignada: RutaAnidada(id: UUID(), nombre: "Ruta demo", activo: true)
            )
        )
    }
}
