//
//  AuthService.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 25/06/26.
//

import Foundation
import Supabase

class AuthService {
    private let supabase = SupabaseManager.shared.client

    // Construye el email interno que nunca ve el usuario
    private func buildEmail(claveOrg: String, clave: String) -> String {
        "\(claveOrg.lowercased()).\(clave.lowercased())@cobrosapp.internal"
    }

    // Genera un codigo random de organización
    func generarClaveOrganizacion() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    // Login para admin y cobrador - misma pantalla, misma logica
    func login(claveOrg: String, clave: String) async throws -> Usuario {
        let email = buildEmail(claveOrg: claveOrg, clave: clave)
        //print("📧 Intentando login con email: \(email)")
        
        do {
            try await supabase.auth.signIn(email: email, password: clave)
            //print("✅ SignIn exitoso")
        } catch {
            //print("❌ Error en signIn: \(error)")
            throw error
        }
        
        let usuario = try await fetchUsuarioActual()
        //print("👤 Usuario obtenido: \(usuario)")
        
        if !usuario.activo {
            try await supabase.auth.signOut()
            throw AuthError.usuarioInactivo
        }
        
        return usuario
    }

    func logout() async throws {
        try await supabase.auth.signOut()
    }

    // Obtiene el perfil del usuario autenticado
    func fetchUsuarioActual() async throws -> Usuario {
        guard let userId = supabase.auth.currentUser?.id else {
            throw AuthError.noAutenticado
        }
        return
            try await supabase
            .from("usuarios")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
    }

    func crearOrganizacion(nombre: String) async throws -> Organizacion {
        let clave = generarClaveOrganizacion()

        // 1. Crear org
        let org: Organizacion =
            try await supabase
            .from("organizaciones")
            .insert(["nombre": nombre, "clave": clave])
            .select()
            .single()
            .execute()
            .value

        // 2. Crear usuario admin en Auth
        let email = buildEmail(claveOrg: clave, clave: "admin")
        let user = try await supabase.auth.admin.createUser(
            attributes: AdminUserAttributes(
                email: email,
                emailConfirm: true,
                password: "admin"
            )
        )

        // 3. Insertar perfil admin en tabla usuarios
        try await supabase
            .from("usuarios")
            .insert([
                "id": user.id.uuidString,
                "organizacion_id": org.id.uuidString,
                "nombre": "Administrador",
                "clave": "admin",
                "rol": "admin",
            ])
            .execute()

        return org
    }

    // El admin crea cobradores desde la app
    func crearCobrador(
        nombre: String,
        clave: String,
        telefono: String?,
        direccion: String?,
        organizacionId: UUID,
        claveOrg: String
    ) async throws {
        struct Payload: Encodable {
            let nombre: String
            let clave: String
            let telefono: String?
            let direccion: String?
            let claveOrg: String
        }
        
        // Obtiene el token de la sesión activa
        guard let token = supabase.auth.currentSession?.accessToken else {
            throw AuthError.noAutenticado
        }

        let payload = Payload(
            nombre: nombre,
            clave: clave,
            telefono: telefono,
            direccion: direccion,
            claveOrg: claveOrg
        )

        try await supabase.functions.invoke(
            "rapid-handler",
            options: FunctionInvokeOptions(
                headers: ["Authorization": "Bearer \(token)"],
                body: payload)
        )
    }

    func fetchUsuarios() async throws -> [Usuario] {
        return
            try await supabase
            .from("usuarios")
            .select()
            .eq("rol", value: "cobrador")
            .order("nombre")
            .execute()
            .value
    }
    
    func toggleActivoCobrador(usuarioId: UUID, activo: Bool) async throws {
        try await supabase
            .from("usuarios")
            .update(["activo": activo])
            .eq("id", value: usuarioId.uuidString)
            .execute()
    }
}

enum AuthError: Error, LocalizedError {
    case noAutenticado
    case usuarioInactivo
    
    var errorDescription: String? {
        switch self {
        case .noAutenticado:
            return "No hay sesión activa"
        case .usuarioInactivo:
            return "Tu cuenta ha sido deshabilitada. Contacta al administrador."
        }
    }
}
