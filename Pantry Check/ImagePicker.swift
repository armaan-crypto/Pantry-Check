//
//  ImagePicker.swift
//  Pantry Check
//
//  Created by Armaan Ahmed on 7/8/24.
//
import SwiftUI

struct CameraPicker: View {
    
    @Binding var selectedImage: UIImage
    @State var fromCamera = false
    
    var body: some View {
        if fromCamera {
            CameraImagePicker(selectedImage: $selectedImage)
        } else {
            PhotosImagePicker(image: $selectedImage)
        }
    }
}

struct PhotosImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage

    func makeUIViewController(context: UIViewControllerRepresentableContext<PhotosImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<PhotosImagePicker>) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotosImagePicker

        init(_ parent: PhotosImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct CameraImagePicker: View {
    
    @Binding var selectedImage: UIImage
    
    var body: some View {
        CameraImagePickerModel(selectedImage: $selectedImage)
            .background(.black)
    }
}

fileprivate struct CameraImagePickerModel: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedImage: UIImage
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        imagePicker.delegate = context.coordinator

        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        var parent: CameraImagePickerModel

        init(_ parent: CameraImagePickerModel) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
            }

            parent.presentationMode.wrappedValue.dismiss()
        }

    }
    
    typealias UIViewControllerType = UIImagePickerController
}

