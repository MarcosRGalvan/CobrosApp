//
//  CredencialesAdminView.swift
//  CobrosAdmin
//
//  Created by Marco Ramirez on 13/07/26.
//

import SwiftUI

struct CredencialesAdminView: View {
    @Environment(\.dismiss) private var dismiss
    let email: String
    let clave: String
    let claveOrg: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)
            
            Text("Organización creada")
                .font(.title2)
                .bold()
            
            Text("Guarda estas credenciales y entrégalas al administrador del negocio.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 350)
            
            VStack(spacing: 12) {
                credencialesRow(titulo: "Clave de organización", valor: claveOrg)
                Divider()
                credencialesRow(titulo: "Contraseña del admin", valor: clave)
            }
            .padding()
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(width: 350)
            
            Text("⚠️ Esta es la única vez que verás la contraseña del admin.")
                .font(.caption)
                .foregroundStyle(.orange)
            
            Button("Cerrar") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(width: 420)
    }
    
    private func credencialesRow(titulo: String, valor: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(valor)
                    .font(.headline)
                    .monospaced()
            }
            Spacer()
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(valor, forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.plain)
            .help("Copiar al portapapeles")
        }
    }
}

#Preview {
    CredencialesAdminView(email: "", clave: "", claveOrg: "")
}
