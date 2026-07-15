//
//  OrganizacionesView.swift
//  CobrosAdmin
//
//  Created by Marco Ramirez on 15/07/26.
//

import SwiftUI

struct OrganizacionesView: View {
    @Bindable var viewModel: OrganizacionesViewModel
    
    var body: some View {
        HSplitView {
            Group {
                if viewModel.isLoading && viewModel.organizaciones.isEmpty {
                    ProgressView("Cargando...")
                } else if viewModel.organizaciones.isEmpty {
                    ContentUnavailableView(
                        "Sin organizaciones",
                        systemImage: "building.2",
                        description: Text("Aún no hay organizaciones creadas.")
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
            .toolbar {
                ToolbarItem {
                    Button {
                        viewModel.generarClave()
                        viewModel.mostrarCrearOrg = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem {
                    Button {
                        Task { await viewModel.crearOrganizacion() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            
            // Detalle
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Organizaciones")
        .task { await viewModel.cargarOrganizaciones() }
        .sheet(isPresented: $viewModel.mostrarCrearOrg) {
            CrearOrganizacionView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.mostrarCredenciales) {
            if let creds = viewModel.credencialesAdmin {
                CredencialesAdminView(
                    email: creds.email,
                    clave: creds.clave,
                    claveOrg: viewModel.organizaciones.last?.clave ?? ""
                )
            }
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
    OrganizacionesView(viewModel: OrganizacionesViewModel())
}
