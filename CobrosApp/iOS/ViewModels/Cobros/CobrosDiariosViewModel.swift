import Foundation

@Observable
@MainActor
class CobrosDiariosViewModel {
    var cobros: [Pago] = []
    var cobrosPageados: [Pago] = []
    var cobrosSinPagar: [Pago] = []
    var isLoading = false
    var errorMessage: String?
    var textoBusqueda: String = ""
    var mostrarSoloPendientes: Bool = true
    var sinRutaAsignada = false
    
    private let service = PagoService()
    private var tareaActual: Task<Void, Never>?
    
    // MARK: - Pendientes filtrados
    
    private var cobrosBase: [Pago] {
        guard !textoBusqueda.isEmpty else { return cobros }
        return cobros.filter {
            $0.nombreCliente.lowercased().contains(textoBusqueda.lowercased())
        }
    }
    
    var cobrosAtrasados: [Pago] {
        let hoy = Calendar.current.startOfDay(for: Date())
        return cobrosBase.filter { pago in
            guard let vencimiento = pago.fechaVencimiento else { return false }
            return Calendar.current.startOfDay(for: vencimiento) < hoy
        }
    }
    
    var cobrosDeHoy: [Pago] {
        let hoy = Calendar.current.startOfDay(for: Date())
        return cobrosBase.filter { pago in
            guard let vencimiento = pago.fechaVencimiento else { return false }
            return Calendar.current.startOfDay(for: vencimiento) == hoy
        }
    }
    
    // MARK: - Pagados filtrados
    
    var cobrosPagadosFiltrados: [Pago] {
        guard !textoBusqueda.isEmpty else { return cobrosPageados }
        return cobrosPageados.filter {
            $0.nombreCliente.lowercased().contains(textoBusqueda.lowercased())
        }
    }
    
    // MARK: - Sin pagar filtrados
    
    var cobrosSinPagarFiltrados: [Pago] {
        guard !textoBusqueda.isEmpty else { return cobrosSinPagar }
        return cobrosSinPagar.filter {
            $0.nombreCliente.lowercased().contains(textoBusqueda.lowercased())
        }
    }
    
    // MARK: - Carga
    
    func cargarCobrosDeHoy(esAdmin: Bool) {
        tareaActual?.cancel()
        tareaActual = Task {
            await MainActor.run { isLoading = true }
            do {
                if !esAdmin {
                    let rutaId = try await RutaService().fetchRutaIdDelCobrador()
                    if rutaId == nil {
                        await MainActor.run {
                            sinRutaAsignada = true
                            isLoading = false
                        }
                        return
                    }
                }
                
                async let pendientes = service.fetchCobrosDiarios()
                async let pagados = service.fetchCobrosDelDiaPorEstado(estado: "pagado")
                async let sinPagar = service.fetchCobrosDelDiaPorEstado(estado: "sin_pagar")
                
                let (p, pg, sp) = try await (pendientes, pagados, sinPagar)
                
                await MainActor.run {
                    cobros = p
                    cobrosPageados = pg
                    cobrosSinPagar = sp
                    isLoading = false
                }
                
            } catch is CancellationError {
                // print("⚠️ Cancelado")
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    // print("❌ Error: \(error)")
                }
            }
        }
    }
}
