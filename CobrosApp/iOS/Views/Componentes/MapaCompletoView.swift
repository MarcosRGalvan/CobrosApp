//
//  MapaCompletoView.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 07/08/26.
//

import SwiftUI
import MapKit

struct MapaCompletoView: View {
    let nombre: String
    let coordenada: CLLocationCoordinate2D
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition
    
    init(nombre: String, coordenada: CLLocationCoordinate2D) {
        self.nombre = nombre
        self.coordenada = coordenada
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: coordenada,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        ))
    }
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                Marker(nombre, coordinate: coordenada)
                    .tint(.red)
            }
            .mapStyle(.standard)
            .ignoresSafeArea(edges: .bottom)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(nombre)
                        .font(.headline)
                }
            }
        }
    }
}

#Preview {
    MapaCompletoView(
            nombre: "Juan Pérez",
            coordenada: CLLocationCoordinate2D(latitude: 20.5217, longitude: -100.8156)
    )
}
