//
//  UbicacionMapaView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/06/26.
//

import SwiftUI
import MapKit

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct UbicacionMapaView: View {
    @Binding var coordenada: CLLocationCoordinate2D?
    @State private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var posicionPin: CLLocationCoordinate2D
    
    init(coordenada: Binding<CLLocationCoordinate2D?>) {
        self._coordenada = coordenada
        let inicial = coordenada.wrappedValue ?? CLLocationCoordinate2D(latitude: 20.5217, longitude: -100.8157)
        self._posicionPin = State(initialValue: inicial)
        self._cameraPosition = State(
                    initialValue: .region(
                        MKCoordinateRegion(
                            center: inicial,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
        )
    }
    
    
    var body: some View {
        VStack(spacing: 12) {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    Marker("Domicilio", coordinate: posicionPin)
                        .tint(.red)
                }
                .mapStyle(.standard)
                .onTapGesture { screenPoint in
                    if let nuevaCoordenada = proxy.convert(screenPoint, from: .local) {
                        posicionPin = nuevaCoordenada
                        coordenada = nuevaCoordenada
                    }
                }
            }
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button {
                locationManager.obtenerUbicacionActual()
            } label: {
                Label("Usar mi ubicación actual", systemImage: "location.fill")
                    .frame(maxWidth: .infinity)
            }
            
            Text("Toca el mapa para ajustar el pin, o usa tu ubicación actual.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            locationManager.obtenerUbicacionActual()
            if coordenada == nil {
                coordenada = posicionPin
            }
        }
        .onChange(of: locationManager.ubicacionActual) { _, nuevaUbicacion in
            guard let nuevaUbicacion else { return }
            posicionPin = nuevaUbicacion
            coordenada = nuevaUbicacion
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: nuevaUbicacion,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { locationManager.errorMessage != nil },
                set: { _ in locationManager.errorMessage = nil }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(locationManager.errorMessage ?? "")
        }
    }
}

#Preview {
    UbicacionMapaView(coordenada: .constant(nil))
}
