//
//  CreatePrestamoView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 21/05/26.
//

import SwiftUI

struct CreatePrestamoView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: PrestamoViewModel
    var clientePreseleccionado: Cliente? = nil
    var onGuardar: (() -> Void)? = nil
    
    @State private var clienteViewModel = ClienteViewModel()
    @State private var clienteSeleccionadoId: Int? = nil
    
    @State private var frecuenciaViewModel = FrecPagoViewModel()
    @State private var frecuenciaSeleccionadaId: Int? = nil
    
    @State private var montoPrestado: Double = 0.0
    @State private var cuotas: Int = 1
    @State private var fechaPrestamo: Date
    @State private var intereses: Double = 0.0
    
    
    // Inicializador de fecha para darles un valor por defecto
    init(viewModel: PrestamoViewModel, clientePreseleccionado: Cliente? = nil, onGuardar: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.clientePreseleccionado = clientePreseleccionado
        self.onGuardar = onGuardar
        _fechaPrestamo = State(initialValue: Date())
    }
    
    var body: some View {
        Form {
            Section(header: Text("Asignación de Cliente")) {
                if clienteViewModel.clientes.isEmpty {
                    Text("Cargando catálogo de clientes...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Clientes", selection: $clienteSeleccionadoId) {
                        Text("Selecciona un cliente")
                            .tag(nil as Int?)
                        ForEach(clienteViewModel.clientes) { cliente in
                            Text("\(cliente.nombre) \(cliente.appaterno)").tag(cliente.id as Int?)
                        }
                    }
                }
            }
            
            Section(header: Text("Detalles del prestamo")) {
                HStack {
                    Text("Monto:")
                    Spacer()
                    TextField("0.0", value: $montoPrestado, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                Stepper("Número de cuotas: \(cuotas)", value: $cuotas, in: 1...100)
                
                if frecuenciaViewModel.frecuencias.isEmpty {
                    ProgressView("Cargando frecuencias...")
                } else {
                    Picker("Frecuencia de cobro", selection: $frecuenciaSeleccionadaId) {
                        Text("Selecciona una frecuencia")
                            .tag(nil as Int?)
                        ForEach(frecuenciaViewModel.frecuencias) { freq in
                            Text(freq.nombre).tag(freq.id as Int?)
                        }
                    }
                }
                
                HStack {
                    Text("Interés (%):")
                    Spacer()
                    TextField("0.0", value: $intereses, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section(header: Text("Fecha del contrato")) {
                DatePicker("Fecha de Inicio", selection: $fechaPrestamo, displayedComponents: .date)
            }
        }
        .navigationTitle("Nuevo Préstamo")
        .interactiveDismissDisabled(viewModel.isLoading)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button("Guardar") {
                        Task {
                            await guardarNuevoPrestamo()
                        }
                    }
                    .fontWeight(.bold)
                    .buttonStyle(.borderedProminent)
                    //.disabled(viewModel.isLoading)
                }
            }
        }
        .task {
            await clienteViewModel.fetchClientes()
            await frecuenciaViewModel.fetchFrecuenciasPago()
            
            if let preseleccionado = clientePreseleccionado {
                await MainActor.run {
                    clienteSeleccionadoId = preseleccionado.id
                }
            }
        }
        .alert("Atención", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private func guardarNuevoPrestamo() async {
        guard let idCliente = clienteSeleccionadoId,
              let idFrecuencia = frecuenciaSeleccionadaId,
              let frecuencia = frecuenciaViewModel.frecuencias.first(where: { $0.id == idFrecuencia })
        else {
            viewModel.errorMessage = "Por favor selecciona un cliente y una frecuencia."
            return
        }
        
        let esValido = viewModel.validarPrestamo(
            clienteId: clienteSeleccionadoId,
            monto: montoPrestado,
            cuotas: cuotas,
            intereses: intereses
        )
        
        guard esValido else { return }
        
        let nuevoPrestamo = Prestamo(
            id: nil,
            clienteId: idCliente,
            montoPrestado: montoPrestado,
            cuotas: cuotas,
            fechaPrestamo: fechaPrestamo,
            frecuenciaPago: idFrecuencia,
            interesPorciento: intereses,
            fechaTermino: nil,
            activo: true,
            cliente: nil
        )
        
        let exito = await viewModel.crearPrestamo(nuevoPrestamo, frecuencia: frecuencia)
        
        if exito {
            if let callback = onGuardar {
                callback()
            } else {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreatePrestamoView(viewModel: PrestamoViewModel())
    }
}
