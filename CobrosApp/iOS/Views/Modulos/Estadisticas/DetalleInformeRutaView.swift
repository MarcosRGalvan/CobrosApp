//
//  DetalleInformeRutaView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 11/09/26.
//

import SwiftUI

struct DetalleInformeRutaView: View {
    let informe: InformeRuta
    let fechaInicio: Date
    let fechaFin: Date
    
    private var rangoTexto: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d MMM"
        return "\(formatter.string(from: fechaInicio)) - \(formatter.string(from: fechaFin))"
    }

    private var efectividad: Double {
        let total = informe.cobrosRealizados + informe.cobrosNoRealizados
        guard total > 0 else { return 0 }
        return Double(informe.cobrosRealizados) / Double(total) * 100
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(rangoTexto)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 8) {
                    Text("Efectividad")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    ZStack {
                        Circle().stroke(Color.gray.opacity(0.2), lineWidth: 16)
                        Circle()
                            .trim(from: 0, to: efectividad / 100)
                            .stroke(efectividad >= 70 ? Color.green : Color.orange, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(efectividad))%")
                            .font(.system(size: 36, weight: .bold))
                    }
                    .frame(width: 150, height: 150)
                }
                .padding()

                VStack(spacing: 16) {
                    MetricasRow(titulo: "Cobrador", valor: informe.cobradorNombre ?? "Sin asignar", icono: "person.fill", color: .blue)
                    MetricasRow(titulo: "Total de clientes", valor: "\(informe.totalClientes)", icono: "person.2.fill", color: .indigo)
                    MetricasRow(titulo: "Cobros realizados", valor: "\(informe.cobrosRealizados)", icono: "checkmark.circle.fill", color: .green)
                    MetricasRow(titulo: "Cobros no realizados", valor: "\(informe.cobrosNoRealizados)", icono: "xmark.circle.fill", color: .red)
                    MetricasRow(titulo: "Total recaudado", valor: informe.totalRecaudado.formatted(.currency(code: "MXN")), icono: "dollarsign.circle.fill", color: .purple)
                    MetricasRow(titulo: "Caja inicial", valor: informe.cajaInicialTotal.formatted(.currency(code: "MXN")), icono: "banknote.fill", color: .teal)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(informe.nombreRuta)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MetricasRow: View {
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

#Preview("Ruta con buen desempeño") {
    NavigationStack {
        DetalleInformeRutaView(
            informe: InformeRuta(
                id: UUID(),
                nombreRuta: "Ruta Norte",
                cobradorNombre: "Marco Ramirez",
                totalClientes: 12,
                cobrosRealizados: 82,
                cobrosNoRealizados: 18,
                totalRecaudado: 8_400,
                cajaInicialTotal: 2_000
            ),
            fechaInicio: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            fechaFin: Date()
        )
    }
}

#Preview("Ruta con problemas") {
    NavigationStack {
        DetalleInformeRutaView(
            informe: InformeRuta(
                id: UUID(),
                nombreRuta: "Ruta Sur",
                cobradorNombre: "Ana López",
                totalClientes: 9,
                cobrosRealizados: 45,
                cobrosNoRealizados: 55,
                totalRecaudado: 3_100,
                cajaInicialTotal: 1_500
            ),
            fechaInicio: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
            fechaFin: Date()
        )
    }
}

#Preview("Sin cobrador asignado") {
    NavigationStack {
        DetalleInformeRutaView(
            informe: InformeRuta(
                id: UUID(),
                nombreRuta: "Ruta Centro",
                cobradorNombre: nil,
                totalClientes: 5,
                cobrosRealizados: 0,
                cobrosNoRealizados: 0,
                totalRecaudado: 0,
                cajaInicialTotal: 0
            ),
            fechaInicio: Calendar.current.startOfDay(for: Date()),
            fechaFin: Date()
        )
    }
}
