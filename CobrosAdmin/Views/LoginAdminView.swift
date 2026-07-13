//
//  LoginAdminView.swift
//  CobrosAdmin
//
//  Created by Marco Ramirez on 10/07/26.
//

import SwiftUI

struct LoginAdminView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var claveOrg = ""
    @State private var clave = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("CobrosAdmin")
                .font(.largeTitle)
                .bold()
            
            Text("Panel de Desarrollador")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Clave de organizacion")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $claveOrg)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Contraseña")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("Contraseña", text: $clave)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
            }
            
            if let error = auth.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            
            Button {
                Task { await auth.login(claveOrg: claveOrg, clave: clave) }
            } label: {
                if auth.isLoading {
                    ProgressView()
                } else {
                    Text("Iniciar Sesión")
                        .frame(width: 200)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(claveOrg.isEmpty || clave.isEmpty || auth.isLoading)
        }
        .frame(width: 400, height: 500)
    }
}

#Preview {
    LoginAdminView()
        .environment(AuthViewModel())
}
