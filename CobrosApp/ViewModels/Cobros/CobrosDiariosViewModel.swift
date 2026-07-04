import Foundation

@Observable
@MainActor
class CobrosDiariosViewModel {
    var cobros: [Pago] = []
    var isLoading = false
    var errorMessage: String?
    
    var textoBusqueda: String = ""
    var mostrarSoloPendientes: Bool = true
    
    private let service = PagoService()
    private var tareaActual: Task<Void, Never>?
    
    private var cobrosBase: [Pago] {
        var resultado = mostrarSoloPendientes
        ? cobros.filter { $0.fechaPago == nil }
        : cobros
        
        if !textoBusqueda.isEmpty {
            resultado = resultado.filter {
                $0.nombreCliente.lowercased().contains(textoBusqueda.lowercased())
            }
        }
        return resultado
    }
    
    // Pagos cuya fecha de vencimiento ya pasó y siguen sin cobrarse
    var cobrosAtrasados: [Pago] {
        let hoy = Calendar.current.startOfDay(for: Date())
        return cobrosBase.filter { pago in
            guard let vencimiento = pago.fechaVencimiento else { return false }
            return Calendar.current.startOfDay(for: vencimiento) < hoy
        }
    }
    
    // Pagos que vencen hoy
    var cobrosDeHoy: [Pago] {
        let hoy = Calendar.current.startOfDay(for: Date())
        return cobrosBase.filter { pago in
            guard let vencimiento = pago.fechaVencimiento else { return false }
            return Calendar.current.startOfDay(for: vencimiento) == hoy
        }
    }
    
    var cobrosFiltrados: [Pago] {
        cobrosBase
    }
    
    func cargarCobrosDeHoy() {
        tareaActual?.cancel()
        tareaActual = Task {
            await MainActor.run { isLoading = true }
            do {
                let resultado = try await service.fetchCobrosDiarios()
                await MainActor.run {
                    cobros = resultado
                    isLoading = false
                    print("✅ isLoading: \(isLoading), cobros: \(cobros.count)")
                }
            } catch is CancellationError {
                print("⚠️ Cancelado")
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    print("❌ Error: \(error)")
                }
            }
        }
    }
}
