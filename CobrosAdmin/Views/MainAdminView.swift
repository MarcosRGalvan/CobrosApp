//
//  MainAdminView.swift
//  CobrosAdmin
//
//  Created by Marco Ramirez on 10/07/26.
//

import SwiftUI

enum AdminDestino: Hashable {
    case organizaciones
    case metricas
}

struct MainAdminView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var destinoSeleccionado: AdminDestino? = .organizaciones
    
    var body: some View {
        NavigationSplitView {
            List(selection: $destinoSeleccionado) {
                Section("General") {
                    Label("Organizaciones", systemImage: "building.2.fill")
                        .tag(AdminDestino.organizaciones)
                    Label("Métricas", systemImage: "chart.bar.fill")
                        .tag(AdminDestino.metricas)
                }
            }
            .navigationTitle("CobrosAdmin")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task { await auth.logout() }
                    } label: {
                        Label("Cerra Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        } detail: {
            switch destinoSeleccionado {
            case .organizaciones:
                OrganizacionesView()
            case .metricas:
                Text("Métricas - próximamente")
            case .none:
                Text("Selecciona una opción del menú")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    MainAdminView()
        .environment(AuthViewModel())
}
