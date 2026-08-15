//
//  AboutAppView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 19/05/26.
//

import SwiftUI

struct AboutAppView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    gradient: Gradient(colors: [Color("AppPrimary"), Color.clear]),
                    startPoint: .bottom,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        Image("icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .shadow(radius: 5)
                        
                        Text("Cobros App")
                            .font(.title .bold())
                            .foregroundStyle(Color("AppDark"))
                        
                        Text("Versión 1.0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 0) {
                        AboutRow(title: "Desarrollador", content: "Marco Ramírez", icon: "person.fill")
                        
                        Divider().padding(.leading, 50)
                        
                        AboutRow(title: "Contacto", content: "marcos.rgalvan@outlook.com", icon: "envelope.fill")
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading) {
                        Spacer()
                        
                        Text("© 2026 Marco Ramírez - Todos los derechos reservados.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.bottom, 20)
                    }
                }
                .navigationTitle("Acerca de la App")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color("AppAlert"))
                    }
                }
            }
        }
    }
}

struct AboutRow: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundStyle(Color("AppDark"))
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(content)
                    .font(.body)
                    .foregroundStyle(Color("AppPrimary"))
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AboutAppView()
}
