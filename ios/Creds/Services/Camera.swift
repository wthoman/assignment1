import SwiftUI
import UIKit
import AVFoundation

enum Camera {
    @MainActor
    /// Checks the camera exists and that Creds may use it. Returns an explanation when it can't be used.
    static func availabilityProblem() async -> String? {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return "There’s no camera available on this device, so the photo can’t be taken. The task stays open until a photo is added."
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return nil
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video) ? nil : deniedMessage
        default:
            return deniedMessage
        }
    }

    static let deniedMessage = "Creds doesn’t have permission to use the camera. Turn it on in Settings › Privacy & Security › Camera, then try again. The task stays open until a photo is added."
}

/// The system camera, photo mode only (no library).
struct CameraPicker: UIViewControllerRepresentable {
    let onPhoto: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onPhoto(image) } else { parent.onCancel() }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.onCancel() }
    }
}
