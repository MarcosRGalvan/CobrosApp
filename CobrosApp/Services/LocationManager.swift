//
//  LocationManager.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 30/06/26.
//

import Foundation
import CoreLocation

@Observable
@MainActor
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var ubicacionActual: CLLocationCoordinate2D?
    var errorMessage: String?
    var autorizado = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    
    func obtenerUbicacionActual() {
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Activa los permisos de ubicación en Ajustes para usar esta función."
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        @unknown default:
            break
        }
    }
    
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            self.autorizado = status == .authorizedWhenInUse || status == .authorizedAlways
            if self .autorizado {
                manager.requestLocation()
            }
        }
    }
    
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            // print("📍 Ubicación obtenida: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            self.ubicacionActual = location.coordinate
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            //print("❌ Error de ubicación: \(error.localizedDescription)")
            self.errorMessage = "No se pudo obtener tu ubicación: \(error.localizedDescription)"
        }
    }
}
