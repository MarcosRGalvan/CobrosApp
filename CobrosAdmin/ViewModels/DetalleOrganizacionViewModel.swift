//
//  DetalleOrganizacionViewModel.swift
//  CobrosAdmin
//
//  Created by Marco Ramirez on 10/07/26.
//

import Foundation

@Observable
@MainActor
class DetalleOrganizacionViewModel {
    var cobradores: [Usuario] = []
    var totalCobradores = 0
    var totalClientes = 0
    var prestamosActivos = 0
    var totalRecaudadoMes: Double = 0
    var isLoading = false
    var errorMessage: String?
    
    private let service = OrganizacionesService()
    
    func cargarDatos(organizacionId: UUID) async {
        isLoading = true
        print("🔍 Cargando datos para org: \(organizacionId)")
        do {
            async let cobradorTask = service.fetchCobradores(organizacionId: organizacionId)
            async let clientesTask = service.fetchTotalClientes(organizacionId: organizacionId)
            async let prestamosTask = service.fetchPrestamosActivos(organizacionId: organizacionId)
            async let recaudadoTask = service.fetchRecaudadoMes(organizacionId: organizacionId)
            
            let (c, cl, p, r) = try await (cobradorTask,clientesTask, prestamosTask, recaudadoTask)
            print("✅ Cobradores: \(c.count), Clientes: \(cl), Préstamos: \(p), Recaudado: \(r)")
            cobradores = c
            totalCobradores = c.count
            totalClientes = cl
            prestamosActivos = p
            totalRecaudadoMes = r
        } catch {
            print("❌ Error: \(error)")
            errorMessage = "Error cargando datos: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
