//
//  DetalleOrganizacionView.swift
//  CobrosAdmin
//
//  Created by Marco Ramirez on 10/07/26.
//

import SwiftUI

struct DetalleOrganizacionView: View {
    let organizacion: Organizacion
    @State private var viewModel = DetalleOrganizacionViewModel()
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "es_MX")
        return f
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(organizacion.nombre)
                        .font(.largeTitle)
                        .bold()
                    HStack {
                        Label(organizacion.clave, systemImage: "key.fill")
                            .foregroundStyle(.secondary)
                        if let fecha = organizacion.createdAt {
                            Divider().frame(height: 16)
                            Label(
                                "Registrar el \(fecha, formatter: dateFormatter)",
                                systemImage: "calendar"
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                }
                
                Divider()
                
                // Méticas
                Text("Resumen")
                    .font(.headline)
                
                if viewModel.isLoading {
                    ProgressView("Cargando datos...")
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 16
                    ) {
                        MetricaAdminCard(
                            titulo: "Cobradores",
                            valor: "\(viewModel.totalCobradores)",
                            icono: "person.2.fill",
                            color: .blue
                        )
                        MetricaAdminCard(
                            titulo: "Clientes",
                            valor: "\(viewModel.totalClientes)",
                            icono: "person.fill",
                            color: .green
                        )
                        MetricaAdminCard(
                            titulo: "Prestamos activos",
                            valor: "\(viewModel.prestamosActivos)",
                            icono: "dollarsign.circle.fill",
                            color: .orange
                        )
                        MetricaAdminCard(
                            titulo: "Recaudado este mes",
                            valor: "\(viewModel.totalRecaudadoMes.formatted(.currency(code: "MXN")))",
                            icono: "banknote.fill",
                            color: .purple
                        )
                    }
                }
                
                Divider()
                
                // Cobradores
                Text("Cobradores")
                    .font(.headline)
                
                if viewModel.cobradores.isEmpty {
                    Text("Sin cobradores registrados")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.cobradores) { cobrador in
                            HStack(spacing: 12) {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(cobrador.activo ? .blue : .gray)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cobrador.nombre)
                                        .font(.headline)
                                    if let tel = cobrador.telefono, !tel.isEmpty {
                                        Text(tel)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Divider()
                                
                                Label(
                                    cobrador.activo ? "Activo" : "Deshabilitado",
                                    systemImage: cobrador.activo ? "checkmark.circle.fill" : "xmark.circle.fill"
                                )
                                .foregroundStyle(cobrador.activo ? .green : .red)
                                .font(.caption)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 4)
                            
                            Divider()
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle(organizacion.nombre)
        .navigationSubtitle("Detalle de organización")
        .task(id: organizacion.id) { await viewModel.cargarDatos(organizacionId: organizacion.id) }
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
    
    struct MetricaAdminCard: View {
        let titulo: String
        let valor: String
        let icono: String
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icono)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(valor)
                    .font(.title)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(titulo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    DetalleOrganizacionView(
        organizacion: Organizacion(
            id: UUID(),
            nombre: "Prestamos García",
            clave: "X7K9P2",
            createdAt: Date()
        )
    )
}
