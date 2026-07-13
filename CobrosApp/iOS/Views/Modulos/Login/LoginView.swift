//
//  LoginView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 26/06/26.
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var auth
    
    @State private var claveOrg = ""
    @State private var clave = ""
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 8) {
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                Text("Cobros App")
                    .font(.largeTitle)
                    .bold()
            }
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Clave de organización")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Ej: X7K9P2", text: $claveOrg)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Contraseña")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SecureField("Contraseña", text: $clave)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            
            if let error = auth.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            
            Button {
                Task { await auth.login(claveOrg: claveOrg, clave: clave) }
            } label: {
                if auth.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Iniciar Sesión").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(claveOrg.isEmpty || clave.isEmpty || auth.isLoading)
            .padding(.horizontal)
            
            Spacer()
        }
    }
}


#Preview {
    LoginView()
        .environment(AuthViewModel())
}
