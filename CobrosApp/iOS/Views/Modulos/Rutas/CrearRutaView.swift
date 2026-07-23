//
//  CrearRutaView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 17/07/26.
//

import SwiftUI

struct CrearRutaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var auth
    @Bindable var viewModel: RutaViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Datos de la ruta")) {
                    TextField("Nombre de la ruta", text: $viewModel.nombreNuevaRuta)
                        .autocorrectionDisabled()
                }
                
                Section {
                    Button {
                        Task {
                            guard let orgId = auth.usuarioActual?.organizacionId else { return }
                            await viewModel.createRuta(organizacionId: orgId)
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Crear Ruta").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.nombreNuevaRuta.isEmpty || viewModel.isLoading)
                }
            }
            .navigationTitle("Nueva Ruta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onChange(of: viewModel.rutaCreada) { _, creada in
                if creada {
                    viewModel.rutaCreada = false
                    dismiss()
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
}

#Preview {
    CrearRutaView(viewModel: RutaViewModel())
        .environment(AuthViewModel())
}
