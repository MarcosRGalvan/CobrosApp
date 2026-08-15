//
//  DetalleClienteView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 29/06/26.
//

import SwiftUI
import MapKit

struct DetalleClienteView: View {
    @State private var cliente: Cliente
    @State private var viewModel: DetalleClienteViewModel
    @Environment(AuthViewModel.self) private var auth
    @State private var mostrarEdicion = false
    @State private var mostrarMapaCompleto = false
    @State private var mostrarDocumentoCompleto = false
    
    private var nombreCompleto: String {
        [cliente.nombre, cliente.appaterno, cliente.apmaterno]
            .compactMap { $0 }
            .joined(separator: " ")
    }
    
    init(cliente: Cliente) {
        _cliente = State(initialValue: cliente)
        _viewModel = State(initialValue: DetalleClienteViewModel(cliente: cliente))
    }
    
    private var coordenada: CLLocationCoordinate2D? {
        guard let lat = cliente.latitud, let lon = cliente.longitud else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    private var degradado: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppPrimary").opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                degradado
                    .frame(height: UIScreen.main.bounds.height / 2)
                    .ignoresSafeArea()
                Spacer()
            }
            
            Form {
                Section(header: Text("Datos del Cliente")) {
                    Label(nombreCompleto, systemImage: "person.crop.circle.fill")
                    Label(cliente.telefono, systemImage: "phone.fill")
                    if let direccion = cliente.direccion, !direccion.isEmpty {
                        Label(direccion, systemImage: "mappin.and.ellipse")
                    }
                    if let email = cliente.email, !email.isEmpty {
                        Label(email, systemImage: "envelope.fill")
                    }
                }
                
                Section(header: Text("Riesgo Crediticio")) {
                    if viewModel.isLoading {
                        ProgressView("Calculando score...")
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Score")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(viewModel.score))%")
                                    .font(.title2)
                                    .bold()
                                    .foregroundStyle(
                                        viewModel.score >= 80 ? .green :
                                            viewModel.score >= 50 ? .orange : .red
                                    )
                                Text(viewModel.scoreDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Incumplimientos")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(viewModel.incumplimientos)")
                                    .font(.title2)
                                    .bold()
                                    .foregroundStyle(viewModel.incumplimientos == 0 ? .green : .red)
                                Text(viewModel.incumplimientos == 0 ? "Sin atrasos" : "Pagos atrasados")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // Barra visual del score
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 10)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        viewModel.score >= 80 ? Color.green :
                                            viewModel.score >= 50 ? Color.orange : Color.red
                                    )
                                    .frame(width: geo.size.width * (viewModel.score / 100), height: 10)
                                    .animation(.easeOut, value: viewModel.score)
                            }
                        }
                        .frame(height: 10)
                    }
                }
                
                
                if cliente.documentoPath != nil {
                    Section(header: Text("Documento de identificación")) {
                        Button {
                            mostrarDocumentoCompleto = true
                        } label: {
                            HStack(spacing: 12) {
                                Group {
                                    if viewModel.cargandoDocumento {
                                        ProgressView()
                                    } else if let url = viewModel.documentoURL {
                                        AsyncImage(url: url) { fase in
                                            switch fase {
                                            case .success(let imagen):
                                                imagen.resizable().scaledToFit()
                                            case .failure:
                                                Image(systemName: "exclamationmark.triangle")
                                                    .foregroundStyle(.secondary)
                                            case .empty:
                                                ProgressView()
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    } else {
                                        Image(systemName: "person.text.rectangle")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tituloDocumento(cliente.documentoTipo ?? ""))
                                        .foregroundStyle(.primary)
                                    Text("Toca para ver")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .disabled(viewModel.documentoURL == nil && !viewModel.cargandoDocumento)
                    }
                }
                
                
                if let coordenada {
                    Section(header: Text("Ubicación del Domicilio")) {
                        Map(position: $cameraPosition) {
                            Marker(nombreCompleto, coordinate: coordenada)
                                .tint(.red)
                        }
                        .mapStyle(.standard)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .listRowInsets(EdgeInsets())
                        .allowsHitTesting(true)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption)
                                .padding(6)
                                .background(.thinMaterial, in: Circle())
                                .padding(8)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            mostrarMapaCompleto = true
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Detalle del Cliente")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.cargarEstadisticas()
            await viewModel.cargarDocumento(cliente: cliente)
        }
        .toolbar {
            if auth.esAdmin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mostrarEdicion = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $mostrarEdicion) {
            NavigationStack {
                CrearClienteView(viewModel: ClienteViewModel(), cliente: cliente) { clienteActualizado in
                    cliente = clienteActualizado
                    mostrarEdicion = false
                }
            }
        }
        .fullScreenCover(isPresented: $mostrarMapaCompleto) {
            if let coordenada {
                MapaCompletoView(nombre: nombreCompleto, coordenada: coordenada)
            }
        }
        .fullScreenCover(isPresented: $mostrarDocumentoCompleto) {
            if let url = viewModel.documentoURL {
                NavigationStack {
                    AsyncImage(url: url) { fase in
                        switch fase {
                        case .success(let imagen):
                            imagen
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            ContentUnavailableView(
                                "No se pudo cargar el documento",
                                systemImage: "exclamationmark.triangle"
                            )
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                mostrarDocumentoCompleto = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        ToolbarItem(placement: .principal) {
                            Text(tituloDocumento(cliente.documentoTipo ?? ""))
                                .font(.headline)
                        }
                    }
                }
            }
        }
        .onAppear {
            if let coordenada {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordenada,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                )
            }
        }
    }
    
    private func tituloDocumento(_ tipo: String) -> String {
        switch tipo {
        case "ine": return "INE"
        case "licencia": return "Licencia de conducir"
        case "comprobante_domicilio": return "Comprobante de domicilio"
        default: return "Documento"
        }
    }
}

#Preview {
    NavigationStack {
        DetalleClienteView(cliente: Cliente(
            id: Int(),
            nombre: "Juan",
            appaterno: "Pérez",
            apmaterno: "López",
            telefono: "4611234567",
            direccion: "Av. Reforma 123, Celaya, Gto",
            email: "juan.perez@ejemplo.com",
            latitud: 20.5217,
            longitud: -100.8156
        ))
    }
    .environment(AuthViewModel())
}
