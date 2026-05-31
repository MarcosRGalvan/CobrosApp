import Foundation

@Observable
@MainActor
class CobrosDiariosViewModel {
    var cobros: [Pago] = []
    var isLoading = false
    var errorMessage: String?
    
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
    
    func marcarComoPagado(pago: Pago, formaPagoId: Int? = nil) async {
        guard let id = pago.id else { return }
        do {
            try await service.registrarPago(
                pagoId: id,
                monto: pago.montoPagado,
                formaPagoId: formaPagoId
            )
            await MainActor.run {
                cobros.removeAll { $0.id == id }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}
