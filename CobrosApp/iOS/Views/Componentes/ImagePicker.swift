//
//  ImagePicker.swift
//  CobrosApp
//
//  Created by Marco Ramirez on 07/08/26.
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    enum Fuente {
        case camara
        case galeria
    }

    let fuente: Fuente
    @Binding var imagenSeleccionada: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = fuente == .camara ? .camera : .photoLibrary
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let imagen = info[.originalImage] as? UIImage {
                parent.imagenSeleccionada = imagen
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
