//
//  InformesRutasView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 11/09/26.
//

import SwiftUI

struct InformesRutasView: View {
    @State private var viewModel = InformesRutasViewModel()
    
    @MainActor
    init() {
        _viewModel = State(initialValue: InformesRutasViewModel())
    }
        
    init(viewModel: InformesRutasViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    private var rangoTexto: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d MMM"
        return "\(formatter.string(from: viewModel.fechaInicio)) - \(formatter.string(from: viewModel.fechaFin))"
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Cargando informes...")
            } else if viewModel.informes.isEmpty {
                ContentUnavailableView("Sin datos", systemImage: "chart.bar.xaxis", description: Text("No hay información para el rango seleccionado."))
            } else {
                List {
                    Section {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text("\(viewModel.rangoSeleccionado.rawValue) · \(rangoTexto)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                    
                    ForEach(viewModel.informes) { informe in
                        NavigationLink {
                            DetalleInformeRutaView(informe: informe, fechaInicio: viewModel.fechaInicio, fechaFin: viewModel.fechaFin)
                        } label: {
                            InformeRutaRow(informe: informe)
                        }
                    }
                }
                .refreshable { await viewModel.cargarInformes() }
            }
        }
        .navigationTitle("Informes de Rutas")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(RangoInforme.allCases) { rango in
                        Button(rango.rawValue) {
                            viewModel.seleccionarRango(rango)
                        }
                    }
                } label: {
                    Label(viewModel.rangoSeleccionado.rawValue, systemImage: "calendar")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("AppPrimary"))
            }
        }
        .sheet(isPresented: $viewModel.mostrarSelectorPersonalizado) {
            NavigationStack {
                Form {
                    DatePicker("Desde", selection: $viewModel.fechaInicio, displayedComponents: .date)
                    DatePicker("Hasta", selection: $viewModel.fechaFin, displayedComponents: .date)
                }
                .navigationTitle("Rango personalizado")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Aplicar") {
                            viewModel.mostrarSelectorPersonalizado = false
                            Task { await viewModel.cargarInformes() }
                        }
                    }
                }
            }
        }
        .task { await viewModel.cargarInformes() }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: {_ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct InformeRutaRow: View {
    let informe: InformeRuta

    private var efectividad: Double {
        let total = informe.cobrosRealizados + informe.cobrosNoRealizados
        guard total > 0 else { return 0 }
        return Double(informe.cobrosRealizados) / Double(total) * 100
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color("AppPrimary").opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "road.lanes.curved.right")
                    .foregroundStyle(Color("AppPrimary"))
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(informe.nombreRuta)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label("\(informe.totalClientes) clientes", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(informe.totalRecaudado.formatted(.currency(code: "MXN")))
                    .font(.subheadline)
                    .bold()
                Text("\(Int(efectividad))% efectividad")
                    .font(.caption)
                    .foregroundStyle(efectividad >= 70 ? .green : .orange)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Con datos") {
    let vm = InformesRutasViewModel()
    vm.informes = [
        InformeRuta(
            id: UUID(),
            nombreRuta: "Ruta Norte",
            cobradorNombre: "Marco Antonio",
            totalClientes: 10,
            cobrosRealizados: 80,
            cobrosNoRealizados: 8,
            totalRecaudado: 30000,
            cajaInicialTotal: 2000),
        InformeRuta(
            id: UUID(),
            nombreRuta: "Ruta Norte",
            cobradorNombre: "Marco Antonio",
            totalClientes: 10,
            cobrosRealizados: 80,
            cobrosNoRealizados: 8,
            totalRecaudado: 30000,
            cajaInicialTotal: 2000),
        InformeRuta(
            id: UUID(),
            nombreRuta: "Ruta Norte",
            cobradorNombre: "Marco Antonio",
            totalClientes: 10,
            cobrosRealizados: 80,
            cobrosNoRealizados: 8,
            totalRecaudado: 30000,
            cajaInicialTotal: 2000),
    ]
    return NavigationStack {
        InformesRutasView(viewModel: vm)
    }
}
