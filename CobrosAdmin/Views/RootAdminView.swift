//
//  RootAdminView.swift
//  CobrosAdmin
//
//  Created by Marco Ramirez on 10/07/26.
//

import SwiftUI

struct RootAdminView: View {
    @Environment(AuthViewModel.self) private var auth
    
    var body: some View {
        Group {
            if auth.isLoading {
                ProgressView("Cargando...")
                    .frame(width: 400, height: 300)
            } else if auth.estaAutenticado {
                MainAdminView()
            } else {
                LoginAdminView()
            }
        }
        .task { await auth.verificarSesion() }
    }
}

#Preview {
    RootAdminView()
        .environment(AuthViewModel())
}
