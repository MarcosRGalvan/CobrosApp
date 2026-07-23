//
//  AsignarCobradorView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 21/07/26.
//

import SwiftUI

struct AsignarCobradorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: DetalleRutaViewModel
    @State private var cobradorSeleccionado: Usuario?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.usuarios.isEmpty {
                    ContentUnavailableView(
                        "Sin cobradores",
                        systemImage: "person.slash.fill",
                        description: Text("No hay cobradores disponibles.")
                    )
                } else {
                    List(viewModel.usuarios.filter { $0.activo && $0.rol == .cobrador}) { usuario in
                        Button {
                            cobradorSeleccionado = usuario
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(usuario.nombre)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    if let tel = usuario.telefono, !tel.isEmpty {
                                        Text(tel)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if cobradorSeleccionado?.id == usuario.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Seleccionar Cobrador")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Asignar") {
                        Task {
                            if let cobrador = cobradorSeleccionado {
                                await viewModel.asignarCobrador(cobradorId: cobrador.id)
                            }
                        }
                    }
                    .disabled(cobradorSeleccionado == nil)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
