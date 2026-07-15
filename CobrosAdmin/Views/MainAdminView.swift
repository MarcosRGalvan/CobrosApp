//
//  MainAdminView.swift
//  CobrosAdmin
//
//  Created by Marco Ramirez on 10/07/26.
//

import SwiftUI

enum AdminDestino: Hashable {
    case organizaciones
    case metricas
}

// MainAdminView.swift
struct MainAdminView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var viewModel = OrganizacionesViewModel()
    @State private var seccionSeleccionada: String? = "organizaciones"

    var body: some View {
        NavigationSplitView {
            // Columna 1: menú principal
            List(selection: $seccionSeleccionada) {
                Section("General") {
                    Label("Organizaciones", systemImage: "building.2.fill")
                        .tag("organizaciones")
                    Label("Métricas", systemImage: "chart.bar.fill")
                        .tag("metricas")
                }
                Section("Herramientas") {
                    Label("Actividad reciente", systemImage: "clock.fill")
                        .tag("actividad")
                }
            }
            .navigationTitle("CobrosAdmin")
            .toolbar {
                ToolbarItem {
                    Button {
                        Task { await auth.logout() }
                    } label: {
                        Label("Cerrar Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        } content: {
            // Columna 2: lista de organizaciones
            switch seccionSeleccionada {
            case "organizaciones":
                Group {
                    if viewModel.isLoading && viewModel.organizaciones.isEmpty {
                        ProgressView("Cargando...")
                    } else if viewModel.organizaciones.isEmpty {
                        ContentUnavailableView(
                            "Sin organizaciones",
                            systemImage: "building.2",
                            description: Text("Aún no hay registradas.")
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
                            viewModel.generarClave()
                            viewModel.mostrarCrearOrg = true
                        } label: { Image(systemName: "plus") }
                    }
                    ToolbarItem {
                        Button {
                            Task { await viewModel.cargarOrganizaciones() }
                        } label: { Image(systemName: "arrow.clockwise") }
                    }
                }
            default:
                ContentUnavailableView(
                    "Selecciona una sección",
                    systemImage: "sidebar.left"
                )
            }
        } detail: {
            // Columna 3: detalle
            switch seccionSeleccionada {
            case "organizaciones":
                if let org = viewModel.organizacionSeleccionada {
                    DetalleOrganizacionView(organizacion: org)
                } else {
                    ContentUnavailableView(
                        "Selecciona una organización",
                        systemImage: "building.2.fill",
                        description: Text("Elige una organización para ver sus detalles.")
                    )
                }
            case "metricas":
                Text("Métricas — próximamente").foregroundStyle(.secondary)
            case "actividad":
                Text("Actividad reciente — próximamente").foregroundStyle(.secondary)
            default:
                ContentUnavailableView(
                    "Selecciona una opción",
                    systemImage: "sidebar.left"
                )
            }
        }
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
    MainAdminView()
        .environment(AuthViewModel())
}
