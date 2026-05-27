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
    
    private let items: [HomeItem] = [
        HomeItem(icon: "person.fill", title: "Clientes", destination: .clientes),
        HomeItem(icon: "dollarsign", title: "Prestamos", destination: .prestamos)
    ]
    
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
                    gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.clear]),
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
                            Image(systemName: "dollarsign")
                                .font(.system(size: 80, weight: .regular))
                                .foregroundStyle(.blue)
                            
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
            .navigationTitle("Hola, Bienvenido")
            .navigationDestination(for: HomeDestination.self) { destination in  // ← NUEVO
                switch destination {
                case .clientes:
                    ClientesListView(path: $path)       // ← pasa el path
                case .prestamos:
                    PrestamosListView()
                }
            }
            .toolbar {
                Button(action: {
                    isPresentingAboutView = true
                }) {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("Acerca de esta App")
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
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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
}
