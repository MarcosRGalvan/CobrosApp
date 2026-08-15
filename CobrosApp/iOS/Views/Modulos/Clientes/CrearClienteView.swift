//
//  CrearClienteView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 20/05/26.
//

import SwiftUI
import MapKit

struct CrearClienteView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: ClienteViewModel
    var onCreate: ((Cliente) -> Void)? = nil
    
    private var clienteExistente: Cliente?
    
    @State private var nombre: String = ""
    @State private var appaterno: String = ""
    @State private var apmaterno: String = ""
    @State private var telefono: String = ""
    @State private var direccion: String = ""
    @State private var email: String = ""
    @State private var coordenada: CLLocationCoordinate2D?
    @State private var documentoTipo: String = "ine"
    @State private var imagenDocumento: UIImage?
    @State private var mostrarSelectorFuente = false
    @State private var mostrarImagePicker = false
    @State private var fuenteImagen: ImagePicker.Fuente = .camara
    
    private var esEdicion: Bool { clienteExistente != nil }
    
    private var degradado: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppPrimary").opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    init(viewModel: ClienteViewModel, cliente: Cliente? = nil, onCreate: ((Cliente) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onCreate = onCreate
        self.clienteExistente = cliente
        
        // Precargar los campos si se esta editando
        _nombre = State(initialValue: cliente?.nombre ?? "")
        _appaterno = State(initialValue: cliente?.appaterno ?? "")
        _apmaterno = State(initialValue: cliente?.apmaterno ?? "")
        _telefono = State(initialValue: cliente?.telefono ?? "")
        _direccion = State(initialValue: cliente?.direccion ?? "")
        _email = State(initialValue: cliente?.email ?? "")
        if let lat = cliente?.latitud, let lon = cliente?.longitud {
            _coordenada = State(initialValue: CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                degradado
                    .frame(height: UIScreen.main.bounds.height / 2)
                    .ignoresSafeArea()
                Spacer()
            }
            
            Form {
                Section(header: Text("Información Personal")) {
                    TextField("Nombre(s)", text: $nombre)
                        .autocorrectionDisabled()
                    TextField("Apellido paterno", text: $appaterno)
                        .autocorrectionDisabled()
                    TextField("Apellido materno", text: $apmaterno)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Contacto")) {
                    TextField("Teléfono (10 dígitos)", text: $telefono)
                        .keyboardType(.phonePad)
                    TextField("Dirección completa", text: $direccion)
                    TextField("Correo electrónico", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Identificación")) {
                    Picker("Tipo de documento", selection: $documentoTipo) {
                        Text("INE").tag("ine")
                        Text("Licencia de conducir").tag("licencia")
                        Text("Comprobante de domicilio").tag("comprobante_domicilio")
                    }
                    
                    if let imagenDocumento {
                        Image(uiImage: imagenDocumento)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture { mostrarSelectorFuente = true }
                    }
                    
                    Button(imagenDocumento == nil ? "Agregar foto del documento" : "Cambiar foto") {
                        mostrarSelectorFuente = true
                    }
                }
                
                Section(header: Text("Ubicación del domicilio")) {
                    UbicacionMapaView(coordenada: $coordenada)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(esEdicion ? "Editar Cliente" : "Nuevo Cliente")
        .interactiveDismissDisabled(viewModel.isLoading)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button(esEdicion ? "Guardar cambios" : "Guardar") {
                        Task {
                            await guardarCliente()
                        }
                    }
                    .fontWeight(.bold)
                    .buttonStyle(.borderedProminent)
                    .tint(Color("AppDark"))
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
        .confirmationDialog("Foto del documento", isPresented: $mostrarSelectorFuente) {
            Button("Tomar foto") {
                fuenteImagen = .camara
                mostrarImagePicker = true
            }
            Button("Elegir de galeria") {
                fuenteImagen = .galeria
                mostrarImagePicker = true
            }
            Button("Cancelar", role: .cancel) {}
        }
        .sheet(isPresented: $mostrarImagePicker) {
            ImagePicker(fuente: fuenteImagen, imagenSeleccionada: $imagenDocumento)
                .ignoresSafeArea()
        }
    }
    
    private func guardarCliente() async {
        let esValido = viewModel.validarCliente(
            nombre: nombre,
            appaterno: appaterno,
            telefono: telefono,
            direccion: direccion
        )
        
        guard esValido else { return }
        
        let clienteAGuardar = Cliente(
            id: clienteExistente?.id,
            nombre: nombre.trimmingCharacters(in: .whitespacesAndNewlines),
            appaterno: appaterno.trimmingCharacters(in: .whitespacesAndNewlines),
            apmaterno: apmaterno.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : apmaterno,
            telefono: telefono.trimmingCharacters(in: .whitespacesAndNewlines),
            direccion: direccion.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : email,
            organizacionId: nil,
            latitud: coordenada?.latitude,
            longitud: coordenada?.longitude

        )
        
        let resultado: Cliente?
        if esEdicion {
            resultado = await viewModel.actualizarCliente(clienteAGuardar)
        } else {
            resultado = await viewModel.crearCliente(clienteAGuardar)
        }
        
        guard let resultado, let clienteId = resultado.id, let organizacionId = resultado.organizacionId else { return }
        
        if let imagenDocumento {
            _ = await viewModel.subirDocumentoIdentificacion(
                image: imagenDocumento,
                tipo: documentoTipo,
                clienteId: clienteId,
                organizacionId: resultado.organizacionId ?? UUID()
            )
        }

        if let callback = onCreate {
            callback(resultado)
        } else {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        CrearClienteView(viewModel: ClienteViewModel())
    }
}
