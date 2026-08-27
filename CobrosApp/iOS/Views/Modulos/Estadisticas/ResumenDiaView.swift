//
//  ResumenDiaView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 27/06/26.
//

import SwiftUI

struct ResumenDiaView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var viewModel = ResumenDiaViewModel()
    
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
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            MetricasCard(titulo: "Cobros Realizados", valor: "\(resumen.cobrosRealizados)", icono: "checkmark.circle.fill", color: .green)
                            MetricasCard(titulo: "Cobros Pendientes", valor: "\(resumen.cobrosPendientes)", icono: "clock.fill", color: .orange)
                            MetricasCard(titulo: "Sin pagar", valor: "\(resumen.cobrosSinPagar)", icono: "xmark.circle.fill", color: .red)
                            MetricasCard(titulo: "Total Recaudado", valor: "\(resumen.totalRecaudado)", icono: "dollarsign.circle.fill", color: .blue)
                            MetricasCard(titulo: "Total Asignados", valor: "\(resumen.cobrosRealizados + resumen.cobrosSinPagar)", icono: "list.bullet.clipboard.fill", color: .purple)
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
    
    struct MetricasCard: View {
        let titulo: String
        let valor: String
        let icono: String
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icono)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
                
                Text(valor)
                    .font(.title2)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(titulo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    ResumenDiaView()
        .environment(AuthViewModel())
}
