//
//  DetalleClienteView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 29/06/26.
//

import SwiftUI
import MapKit

struct DetalleClienteView: View {
    let cliente: Cliente
    @State private var viewModel: DetalleClienteViewModel
    
    private var nombreCompleto: String {
        [cliente.nombre, cliente.appaterno, cliente.apmaterno]
            .compactMap { $0 }
            .joined(separator: " ")
    }
    
    init(cliente: Cliente) {
        self.cliente = cliente
        _viewModel = State(initialValue: DetalleClienteViewModel(cliente: cliente))
    }
    
    private var coordenada: CLLocationCoordinate2D? {
        guard let lat = cliente.latitud, let lon = cliente.longitud else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
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
                }
            }
        }
        .navigationTitle("Detalle del Cliente")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.cargarEstadisticas() }
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
}

#Preview {
    NavigationStack {
        DetalleClienteView(
            cliente: Cliente(
                nombre: "Marco",
                appaterno: "Ramirez",
                apmaterno: "Galvan",
                telefono: "4353453454",
                direccion: "Calle Falsa 123",
                email: "marco@email.com",
                organizacionId: nil,
                latitud: 20.5217,
                longitud: -100.8157
            )
        )
    }
}
