//
//  CrearClienteView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 20/05/26.
//

import SwiftUI

struct CrearClienteView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: ClienteViewModel
    
    @State private var nombre: String = ""
    @State private var appaterno: String = ""
    @State private var apmaterno: String = ""
    @State private var telefono: String = ""
    @State private var direccion: String = ""
    @State private var email: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Información Personal")) {
                TextField("Nombre(s)", text: $nombre)
                    .autocorrectionDisabled()
                TextField("Apellido paterno", text: $appaterno)
                    .autocorrectionDisabled()
                TextField("Apellido materno", text: $apmaterno)
                    .autocorrectionDisabled()
            }
            
            Section(header: Text("Contacto y Ubicación")) {
                TextField("Teléfono (10 dígitos)", text: $telefono)
                    .keyboardType(.phonePad)
                TextField("Dirección completa", text: $direccion)
                TextField("Correo electrónico", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .navigationTitle("Nuevo Cliente")
        //.navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.isLoading) // esto evita que el usuario haga el gesto de volver a la pantalla anterior
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button("Guardar") {
                        Task {
                            await guardarCliente()
                        }
                    }
                    .fontWeight(.bold)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .alert("Atención", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private func guardarCliente() async {
        let esValido = viewModel.validarCliente(
            nombre: nombre,
            appaterno: appaterno,
            telefono: telefono,
            direccion: direccion
        )
        
        guard esValido else { return }
        
        let nuevoCliente = Cliente(
            id: nil,
            nombre: nombre.trimmingCharacters(in: .whitespacesAndNewlines),
            appaterno: appaterno.trimmingCharacters(in: .whitespacesAndNewlines),
            apmaterno: apmaterno.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : apmaterno,
            telefono: telefono.trimmingCharacters(in: .whitespacesAndNewlines),
            direccion: direccion.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : email
        )
        
        let guardadoExitoso = await viewModel.crearCliente(nuevoCliente)
        
        if guardadoExitoso {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        CrearClienteView(viewModel: ClienteViewModel())
    }
}
