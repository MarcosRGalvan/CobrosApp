//
//  AsignarCajaView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 10/09/26.
//

import SwiftUI

struct AsignarCajaView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: DetalleRutaViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Monto")) {
                    TextField("$0.00", text: $viewModel.montoCajaTexto)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .bold()
                }
            }
            .navigationTitle("Caja del dia")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { viewModel.mostrarAsignarCaja = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        Task { await viewModel.guardarCaja() }
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}
