//
//  DataScanner.swift
//  Pantry Check
//
//  Created by Armaan Ahmed on 7/7/24.
//
import SwiftUI
import VisionKit

struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var shouldStartScanning: Bool
    @Binding var scannedText: String
    var dataToScanFor: Set<DataScannerViewController.RecognizedDataType>
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
       var parent: DataScannerRepresentable
       
       init(_ parent: DataScannerRepresentable) {
           self.parent = parent
       }
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            if allItems.count > 0 {
                let item = allItems[0]
                switch item {
                case .text(let text):
                    parent.scannedText = text.transcript
                case .barcode(let barcode):
                    parent.scannedText = barcode.payloadStringValue ?? "Unable to decode the scanned code"
                default:
                    print("unexpected item")
                }
            }
        }
    }
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let dataScannerVC = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        
        dataScannerVC.delegate = context.coordinator
       
       return dataScannerVC
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
       if shouldStartScanning {
           try? uiViewController.startScanning()
       } else {
           uiViewController.stopScanning()
       }
    }

    func makeCoordinator() -> Coordinator {
       Coordinator(self)
    }
}
