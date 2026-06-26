//
//  RootView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 26/06/26.
//

import SwiftUI

struct RootView: View {
    @Environment(AuthViewModel.self) private var auth
    
    var body: some View {
        Group {
            if auth.isLoading {
                ProgressView("Cargando...")
            } else if auth.estaAutenticado {
                ContentView()
            } else {
                LoginView()
            }
        }
        .task { await auth.verificarSesion() }
    }
}
