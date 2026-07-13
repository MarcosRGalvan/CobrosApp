//
//  OrganizacionesView.swift
//  CobrosAdmin
//
//  Created by Marco Ramirez on 10/07/26.
//

import SwiftUI

struct OrganizacionesView: View {
    @State private var viewModel = OrganizacionesViewModel()
    
    var body: some View {
        NavigationSplitView {
            Group {
                if viewModel.isLoading && viewModel.organizaciones.isEmpty {
                    ProgressView("Cargando...")
                } else if viewModel.organizaciones.isEmpty {
                    ContentUnavailableView(
                        "Sin organizaciones",
                        systemImage: "building.2",
                        description: Text("Aún no hay organizaciones registradas.")
                    )
                } else {
                    List(
                        viewModel.organizaciones,
                        selection: $viewModel.organizacionSeleccionada
                    ) { org in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(org.nombre)
                                .font(.headline)
                            Label(org.clave, systemImage: "key.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .tag(org)
                    }
                }
            }
            .navigationTitle("Organizaciones")
            .toolbar {
                ToolbarItem {
                    Button {
                        Task { await viewModel.cargarOrganizaciones() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        } detail: {
            if let org = viewModel.organizacionSeleccionada {
                DetalleOrganizacionView(organizacion: org)
            } else {
                ContentUnavailableView(
                    "Selecciona una organización",
                    systemImage: "building.2.fill",
                    description: Text("Elige una organización de la lista para ver sus detalles.")
                )
            }
        }
        .task { await viewModel.cargarOrganizaciones() }
        .sheet(isPresented: $viewModel.mostrarCrearOrg) {
            CrearOrganizacionesView(viewModel: viewModel)
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
    OrganizacionesView()
}
