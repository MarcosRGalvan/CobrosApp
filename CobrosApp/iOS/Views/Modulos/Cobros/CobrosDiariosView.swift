//
//  CobrosDiariosView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/05/26.
//

import SwiftUI

struct CobrosDiariosView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = CobrosDiariosViewModel()
    @State private var pagoSeleccionado: Pago? = nil
    @State private var tabSeleccionada = 0
    
    private var esAdmin: Bool {
        authViewModel.usuarioActual?.rol == .admin
    }
    
    private var fondoEncabezado: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppPrimary").opacity(0.85)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Picker("", selection: $tabSeleccionada) {
                Text("Pendientes (\(viewModel.cobros.count))").tag(0)
                Text("Pagados (\(viewModel.cobrosPageados.count))").tag(1)
                Text("Sin pagar (\(viewModel.cobrosSinPagar.count))").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView("Cargando cobros...")
                Spacer()
            } else {
                TabView(selection: $tabSeleccionada) {
                    pendientesTab.tag(0)
                    pagadosTab.tag(1)
                    sinPagarTab.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationTitle("Cobros del Día")
        .toolbarBackground(fondoEncabezado, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        //.toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $viewModel.textoBusqueda, prompt: "Buscar cliente...")
        .onAppear { viewModel.cargarCobrosDeHoy(esAdmin: esAdmin) }
        .refreshable { viewModel.cargarCobrosDeHoy(esAdmin: esAdmin) }
        .navigationDestination(item: $pagoSeleccionado) { pago in
            DetallePagoView(pago: pago, cliente: pago.prestamos?.clientes)
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
        .alert(
            "Sin ruta asignada",
            isPresented: $viewModel.sinRutaAsignada
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No tienes una ruta asignada. Contacta a tu supervisor para que te asigne una.")
        }
    }
    
    // MARK: - Tabs
    
    private var pendientesTab: some View {
        Group {
            if viewModel.cobros.isEmpty {
                ContentUnavailableView(
                    "Sin cobros pendientes",
                    systemImage: "checkmark.seal.fill",
                    description: Text("No hay pagos pendientes por hoy.")
                )
            } else if viewModel.cobrosDeHoy.isEmpty && viewModel.cobrosAtrasados.isEmpty {
                ContentUnavailableView.search(text: viewModel.textoBusqueda)
            } else {
                List {
                    if !viewModel.cobrosDeHoy.isEmpty {
                        seccionCobros(
                            titulo: "Vencen hoy",
                            pagos: viewModel.cobrosDeHoy,
                            esAtrasado: false
                        )
                    }
                    if !viewModel.cobrosAtrasados.isEmpty {
                        seccionCobros(
                            titulo: "Atrasados",
                            pagos: viewModel.cobrosAtrasados,
                            esAtrasado: true
                        )
                    }
                }
            }
        }
    }
    
    private var pagadosTab: some View {
        Group {
            if viewModel.cobrosPagadosFiltrados.isEmpty {
                ContentUnavailableView(
                    "Sin pagos registrados",
                    systemImage: "dollarsign.circle",
                    description: Text("Aún no se han registrado pagos hoy.")
                )
            } else {
                List {
                    ForEach(viewModel.cobrosPagadosFiltrados) { pago in
                        Button {
                            pagoSeleccionado = pago
                        } label: {
                            CobroDiariosRow(pago: pago)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                    }
                }
            }
        }
    }
    
    private var sinPagarTab: some View {
        Group {
            if viewModel.cobrosSinPagarFiltrados.isEmpty {
                ContentUnavailableView(
                    "Sin incidencias",
                    systemImage: "hand.thumbsup.fill",
                    description: Text("No hay clientes registrados sin pago hoy.")
                )
            } else {
                List {
                    ForEach(viewModel.cobrosSinPagarFiltrados) { pago in
                        Button {
                            pagoSeleccionado = pago
                        } label: {
                            CobroDiariosRow(pago: pago)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func seccionCobros(titulo: String, pagos: [Pago], esAtrasado: Bool) -> some View {
        Section {
            ForEach(pagos) { pago in
                Button {
                    pagoSeleccionado = pago
                } label: {
                    CobroDiariosRow(pago: pago)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
            }
        } header: {
            if esAtrasado {
                Label(titulo, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } else {
                Text(titulo)
            }
        }
    }
}

// MARK: - Row

struct CobroDiariosRow: View {
    let pago: Pago
    
    private var uiDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }
    
    private var diasAtraso: Int? {
        guard let vencimiento = pago.fechaVencimiento,
              pago.fechaPago == nil else { return nil }
        let hoy = Calendar.current.startOfDay(for: Date())
        let dias = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: vencimiento),
            to: hoy
        ).day ?? 0
        return dias > 0 ? dias : nil
    }
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 4) {
                    Text(pago.nombreCliente)
                        .font(.title3)
                        .bold()
                    if let cuota = pago.numeroCuota {
                        Text("Pago: \(cuota)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let fecha = pago.fechaVencimiento {
                        Text("Fecha vence: \(fecha, formatter: uiDateFormatter)")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.orange)
                    }
                    if let dias = diasAtraso {
                        Text("\(dias) día\(dias == 1 ? "" : "s") de atraso")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.red)
                    }
                    Text("Total pago: \(pago.montoPagado, format: .currency(code: "MXN"))")
                        .font(.body)
                        .bold()
                        .foregroundStyle(.green)
                }
            }
            .padding(.vertical, 4)
            .padding(.leading, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            VStack(spacing: 4) {
                switch pago.estado {
                case .pagado:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                        .font(.title3)
                    Text("Pagado")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.white)
                case .pendiente:
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.white)
                        .font(.title3)
                    Text("Pendiente")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.white)
                default:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white)
                        .font(.title3)
                    Text("Sin pagar")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 90)
            .frame(maxHeight: .infinity)
            .background(
                pago.estado == .pagado ? Color.green :
                    pago.estado == .pendiente ? Color.orange :
                    Color.red
            )
        }
        .frame(height: 110)
    }
}

#Preview {
    NavigationStack {
        CobrosDiariosView()
    }
    .environment(AuthViewModel())
}
