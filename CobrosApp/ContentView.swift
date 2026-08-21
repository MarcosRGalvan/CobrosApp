//
//  ContentView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 19/05/26.
//

import SwiftUI

struct HomeItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let destination: HomeDestination
}

struct ContentView: View {
    @State private var isPresentingAboutView = false
    @State private var path = NavigationPath()          // ← NUEVO
    @Environment(AuthViewModel.self) private var auth
    
    private var items: [HomeItem] {
        var result: [HomeItem] = []
        
        if !auth.esAdmin {
            result.append(HomeItem(icon: "road.lanes.curved.right", title: "Ruta del Dia", destination: .rutaDelDia))
            result.append(HomeItem(icon: "chart.bar.fill", title: "Mi Resumen", destination: .resumenDia))
        }
        
        result.append(contentsOf: [
            HomeItem(icon: "person.fill", title: "Clientes", destination: .clientes),
            HomeItem(icon: "dollarsign", title: "Prestamos", destination: .prestamos),
        ])
        
        if auth.esAdmin {
            result.append(HomeItem(icon: "person.badge.shield.checkmark.fill", title: "Cobradores", destination: .usuarios))
            result.append(HomeItem(icon: "road.lanes", title: "Rutas", destination: .rutas))
            result.append(HomeItem(icon: "chart.line.uptrend.xyaxis", title: "Informes", destination: .informe))
        }
        
        return result
    }
    
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 120), spacing: 12)
    ]
    
    private var formatedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    
    var body: some View {
        NavigationStack(path: $path) {                  // ← path aquí
            ZStack(alignment: .top) {
                LinearGradient(
                    gradient: Gradient(colors: [Color("AppPrimary"), Color.clear]),
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(formatedDate.capitalized)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.top, -8)
                            .padding(.leading)
                        
                        VStack(spacing: 16) {
                            Image("icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 110, height: 110)
                            
                            Text("Cobros App")
                                .font(.system(size: 35, weight: .regular))
                            
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(items) { item in
                                    NavigationLink(value: item.destination) {  // ← value en vez de destination
                                        Tile(icon: item.icon, title: item.title)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Hola, \(auth.usuarioActual?.nombre.components(separatedBy: " ").first ?? "Bienvenido")")
            .navigationDestination(for: HomeDestination.self) { destination in  // ← NUEVO
                switch destination {
                case .clientes:
                    ClientesListView(path: $path)
                case .prestamos:
                    PrestamosListView(path: $path)
                case .crearPrestamo(let cliente):
                    CreatePrestamoView(
                        viewModel: PrestamoViewModel(),
                        clientePreseleccionado: cliente
                    )
                case .resumenDia:
                    ResumenDiaView()
                case .informe:
                    EmptyView()
                case .rutaDelDia:
                    CobrosDiariosView()
                case .usuarios:
                    UsuariosListView()
                case .configuracion:
                    EmptyView()
                case .rutas:
                    RutaListView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await auth.logout() }
                    } label: {
                        Label("Cerrar Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .tint(.red)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isPresentingAboutView = true
                    }) {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("Acerca de esta App")
                }
            }
            .sheet(isPresented: $isPresentingAboutView) {
                AboutAppView()
            }
        }
    }
}

private struct Tile: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color("AppAlert"))
                .frame(width: 44, height: 44)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(Color("AppAlert"))
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}
