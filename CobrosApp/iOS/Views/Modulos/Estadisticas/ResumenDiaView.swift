//
//  ResumenDiaView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 27/06/26.
//

import SwiftUI

struct ResumenDiaView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var viewModel: ResumenDiaViewModel

    @MainActor
    init() {
        _viewModel = State(initialValue: ResumenDiaViewModel())
    }

    init(viewModel: ResumenDiaViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var formatedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Cargando resumen...")
            } else if let resumen = viewModel.resumen {
                ScrollView {
                    VStack(spacing: 20) {
                        Text(formatedDate.capitalized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        // Efectividad
                        VStack(spacing: 8) {
                            Text("Efectividad")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 16)
                                Circle()
                                    .trim(from: 0, to: resumen.efectividad / 100)
                                    .stroke(
                                        resumen.efectividad >= 70 ? Color.green : Color.orange,
                                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeOut, value: resumen.efectividad)
                                
                                Text("\(Int(resumen.efectividad))%")
                                    .font(.system(size: 36, weight: .bold))
                            }
                            .frame(width: 150, height: 150)
                        }
                        .padding()
                        
                        // Tarjetas de métricas
                        VStack(spacing: 16) {
                            MetricasRow(titulo: "Cobros Realizados", valor: "\(resumen.cobrosRealizados)", icono: "checkmark.circle.fill", color: .green)
                            MetricasRow(titulo: "Cobros Pendientes", valor: "\(resumen.cobrosPendientes)", icono: "clock.fill", color: .orange)
                            MetricasRow(titulo: "Sin pagar", valor: "\(resumen.cobrosSinPagar)", icono: "xmark.circle.fill", color: .red)
                            MetricasRow(titulo: "Total Recaudado", valor: resumen.totalRecaudado.formatted(.currency(code: "MXN")), icono: "dollarsign.circle.fill", color: .blue)
                            MetricasRow(titulo: "Total Asignados", valor: "\(resumen.cobrosRealizados + resumen.cobrosSinPagar)", icono: "list.bullet.clipboard.fill", color: .purple)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            } else {
                ContentUnavailableView("Sin datos", systemImage: "chart.bar.xaxis", description: Text("No hay cobros asignados para hoy."))
            }
        }
        .navigationTitle("Mi resumen")
        .task {
            guard let userId = auth.usuarioActual?.id else { return }
            await viewModel.cargarResumen(cobradorId: userId)
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
    
    struct MetricasRow: View {
        let titulo: String
        let valor: String
        let icono: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 16) {
                Image(systemName: icono)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 36)
                
                Text(titulo)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(valor)
                    .font(.title3)
                    .bold()
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Mockups para visualizar el diseño

#Preview("Alta efectividad") {
    let vm = ResumenDiaViewModel()
    vm.resumen = ResumenDia(
        cobrosRealizados: 18,
        cobrosPendientes: 4,
        cobrosSinPagar: 3,
        totalRecaudado: 12_500,
        efectividad: 78
    )
    return NavigationStack {
        ResumenDiaView(viewModel: vm)
    }
    .environment(AuthViewModel())
}

#Preview("Baja efectividad") {
    let vm = ResumenDiaViewModel()
    vm.resumen = ResumenDia(
        cobrosRealizados: 6,
        cobrosPendientes: 9,
        cobrosSinPagar: 11,
        totalRecaudado: 3_200,
        efectividad: 35
    )
    return NavigationStack {
        ResumenDiaView(viewModel: vm)
    }
    .environment(AuthViewModel())
}

#Preview("Sin datos") {
    NavigationStack {
        ResumenDiaView()
    }
    .environment(AuthViewModel())
}
