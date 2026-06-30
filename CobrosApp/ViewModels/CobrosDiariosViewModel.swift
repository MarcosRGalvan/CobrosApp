import Foundation

@Observable
@MainActor
class CobrosDiariosViewModel {
    var cobros: [Pago] = []
    var isLoading = false
    var errorMessage: String?
    
    var textoBusqueda: String = ""
    var mostrarSoloPendientes: Bool = false
    
    var cobrosFiltrados: [Pago] {
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
    
    private let service = PagoService()
    private var tareaActual: Task<Void, Never>?
    
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
