//
//  CrearOrganizacionesView.swift
//  CobrosAdmin
//
//  Created by Marco Ramirez on 11/07/26.
//

import SwiftUI

struct CrearOrganizacionesView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: OrganizacionesViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Nueva Organización")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre del negocio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Ej: Prestamos García", text: $viewModel.nombreNuevaOrg)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Clave de organización")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    TextField("Clave", text: $viewModel.claveGenerada)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                        .disabled(true)
                    Button("Regenerar") {
                        viewModel.generarClave()
                    }
                }
                Text("Esta clave la usarán el admin y los cobradores para iniciar sesión.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 300)
            }
            
            HStack(spacing: 12) {
                Button("Cancelar") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button {
                    Task { await viewModel.crearOrganizacion() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Crear Organización")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.nombreNuevaOrg.isEmpty || viewModel.isLoading)
            }
        }
        .padding(32)
        .frame(width: 420)
        .onChange(of: viewModel.orgCreada) { _, creada in
            if creada {
                viewModel.orgCreada = false
                dismiss()
            }
        }
    }
}

 #Preview {
     CrearOrganizacionesView(viewModel: OrganizacionesViewModel())
 }
