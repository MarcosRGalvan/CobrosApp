//
//  ComprobanteService.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 02/09/26.
//

import UIKit

struct ComprobanteData {
    let organizacionNombre: String
    let folio: String
    let fechaPago: Date
    let clienteNombre: String
    let numeroCuota: Int
    let totalCuotas: Int
    let montoPagado: Double
    let abonoCapital: Double
    let pagoIntereses: Double
    let recargos: Double
    let formaPago: String
    let saldoRestante: Double
}

enum ComprobanteService {
    static func generarPDF(data: ComprobanteData) -> URL? {
        let pageWidth: CGFloat = 320
        let pageHeight: CGFloat = 560
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let fileName = "comprobante_\(data.folio).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let colorPrimario = UIColor(named: "AppPrimary") ?? UIColor.systemTeal
        
        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                var y: CGFloat = 0
                
                let titleFont = UIFont.boldSystemFont(ofSize: 18)
                let headerFont = UIFont.boldSystemFont(ofSize: 13)
                let regularFont = UIFont.systemFont(ofSize: 11)
                let smallFont = UIFont.systemFont(ofSize: 9)
                
                func draw(_ text: String, font: UIFont, color: UIColor = .black) {
                    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                    NSAttributedString(string: text, attributes: attrs)
                        .draw(at: CGPoint(x: 20, y: y))
                    y += font.lineHeight + 4
                }
                
                func drawRow(_ label: String, _ value: String) {
                    let attrs: [NSAttributedString.Key: Any] = [.font: regularFont, .foregroundColor: UIColor.black]
                    NSAttributedString(string: label, attributes: attrs).draw(at: CGPoint(x: 20, y: y))
                    let valueString = NSAttributedString(string: value, attributes: attrs)
                    valueString.draw(at: CGPoint(x: pageWidth - 20 - valueString.size().width, y: y))
                    y += regularFont.lineHeight + 6
                }
                
                func drawDivider() {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: 20, y: y))
                    path.addLine(to: CGPoint(x: pageWidth - 20, y: y))
                    UIColor.lightGray.setStroke()
                    path.lineWidth = 0.5
                    path.stroke()
                    y += 10
                }
                
                // Encabezado con color de fondo
                let headerHeight: CGFloat = 110
                let headerRect = CGRect(x: 0, y: 0, width: pageWidth, height: headerHeight)
                colorPrimario.setFill()
                UIBezierPath(rect: headerRect).fill()
                
                y = 24
                draw(data.organizacionNombre, font: titleFont, color: .white)
                draw("Comprobante de Pago", font: headerFont, color: .white)
                draw("Folio: \(data.folio)", font: smallFont, color: .white.withAlphaComponent(0.85))
                
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "es_MX")
                dateFormatter.dateStyle = .full
                dateFormatter.timeStyle = .short
                draw(dateFormatter.string(from: data.fechaPago), font: smallFont, color: .white.withAlphaComponent(0.85))
                
                y = headerHeight + 20
                
                draw("Cliente", font: headerFont)
                draw(data.clienteNombre, font: regularFont)
                draw("Cuota \(data.numeroCuota) de \(data.totalCuotas)", font: regularFont, color: .darkGray)
                
                drawDivider()
                
                draw("Desglose del pago", font: headerFont)
                drawRow("Intereses:", data.pagoIntereses.formatted(.currency(code: "MXN")))
                if data.recargos > 0 {
                    drawRow("Recargos:", data.recargos.formatted(.currency(code: "MXN")))
                }
                drawRow("Abono a capital:", data.abonoCapital.formatted(.currency(code: "MXN")))
                drawRow("Forma de pago:", data.formaPago)
                
                drawDivider()
                
                draw("Total pagado", font: headerFont)
                draw(data.montoPagado.formatted(.currency(code: "MXN")), font: UIFont.boldSystemFont(ofSize: 22))
                y += 6
                drawRow("Saldo restante:", data.saldoRestante.formatted(.currency(code: "MXN")))
                
                drawDivider()
                draw("Gracias por su pago", font: smallFont, color: .gray)
            }
            return url
        } catch {
            print("Error generando PDF: \(error)")
            return nil
        }
    }
}
