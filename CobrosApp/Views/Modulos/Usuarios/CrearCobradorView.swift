//
//  CrearCobradorView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 26/06/26.
//

import Supabase
import SwiftUI

struct CrearCobradorView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = UsuariosViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Datos del Cobrador")) {
                    HStack {
                        Label("", systemImage: "person.fill")
                        TextField("Nombre completo", text: $viewModel.nombre)
                    }

                    HStack {
                        Label("", systemImage: "phone.fill")
                        TextField(
                            "Teléfono (opcional)",
                            text: $viewModel.telefono
                        )
                        .keyboardType(.phonePad)
                    }

                    HStack {
                        Label("", systemImage: "mappin.and.ellipse")
                        TextField("Dirección", text: $viewModel.direccion)
                    }
                }

                Section(header: Text("Acceso")) {
                    HStack {
                        Label("", systemImage: "key.fill")
                        TextField("Clave de acceso", text: $viewModel.clave)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }

                    Text(
                        "El cobrador usará la clave de organización + esta clave para ingresar."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        Task {
                            print("👆 Botón tocado")
                            print(
                                "👤 Usuario actual: \(String(describing: auth.usuarioActual))"
                            )

                            guard let orgId = auth.usuarioActual?.organizacionId
                            else {
                                print("❌ No hay organizacionId")
                                return
                            }
                            print("✅ orgId: \(orgId)")

                            guard
                                let claveOrg = await fetchClaveOrg(orgId: orgId)
                            else {
                                print("❌ No se pudo obtener claveOrg")
                                return
                            }
                            print("✅ claveOrg: \(claveOrg)")

                            await viewModel.crearCobrador(
                                organizacionId: orgId,
                                claveOrg: claveOrg
                            )
                            print(
                                "✅ crearCobrador terminó, usuarioCreado: \(viewModel.usuarioCreado), error: \(String(describing: viewModel.errorMessage))"
                            )
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Crear Cobrador").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Nuevo Cobrador")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onChange(of: viewModel.usuarioCreado) { _, creado in
                if creado { dismiss() }
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { _ in viewModel.errorMessage = nil }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func fetchClaveOrg(orgId: UUID) async -> String? {
        struct OrgClave: Decodable { let clave: String }
        do {
            let result: OrgClave = try await SupabaseManager.shared.client
                .from("organizaciones")
                .select("clave")
                .eq("id", value: orgId)
                .single()
                .execute()
                .value

            return result.clave
        } catch {
            print("❌ Error fetchClaveOrg: \(error)")
            return nil
        }
    }
}
