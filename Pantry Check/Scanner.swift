//
//  Scanner.swift
//  Pantry Check
//
//  Created by Armaan Ahmed on 7/7/24.
//

import SwiftUI
import CodeScanner
import AlertToast

class ScannerModel: ObservableObject {
//    @Published var scannedFoods: [Food] = [Food(id: 1, name: "Food", upc: "124", image: "https://images.openfoodfacts.org/images/products/003/000/062/3619/front_en.5.400.jpg", category: "", quantity: 1), Food(id: 1, name: "Food", upc: "124", image: "https://images.openfoodfacts.org/images/products/003/000/062/3619/front_en.5.400.jpg", category: "", quantity: 1)]
    @Published var scannedFoods: [Food] = []
    @Published var sum = 0
    
    func addFood(_ upc: String) async throws {
        if scannedFoods.contains(where: { $0.upc == upc }) {
            DispatchQueue.main.async { [self] in
                scannedFoods[scannedFoods.firstIndex(where: { $0.upc == upc })!].increment()
                sum += 1
            }
            return
        }
        let url = URL(string: K.hostname + "/getFood?upc=" + upc)!
        let (data, _) = try await URLSession.shared.data(from: url)
        print(String(data: data, encoding: .utf8))
        let food = try JSONDecoder().decode(FoodData.self, from: data)
        DispatchQueue.main.async { [self] in
            scannedFoods.append(food.toFood())
            sum += 1
        }
    }
}

struct Scanner: View {
    
    @Binding var isShowing: Bool
    @Binding var roomId: Int
    @StateObject var model = ScannerModel()
    @State var scannedCode = ""
    @State var couldntFind = false
    @State var canScan = true
    
    @State var loading = false
    @State var isError = false
    @State var error = ""
    
    var body: some View {
        ZStack {
            VStack {
                DataScannerRepresentable(
                    shouldStartScanning: $canScan,
                    scannedText: $scannedCode,
                    dataToScanFor: [.barcode()]
                )
                .frame(height: 200)
                Spacer()
            }
            if model.scannedFoods.count > 0 {
                ScrollView {
                    VStack {
                        Spacer().frame(height: (UIScreen.main.bounds.height / 2) - 50)
                        VStack {
                            Divider()
                            Text("Total of \(model.sum) Items")
                            Divider()
                            ForEach($model.scannedFoods) { food in
                                ScannedItemCard(food: food) { _ in
                                    let i = model.scannedFoods.firstIndex(where: { $0.id == food.id })!
                                    withAnimation {
                                        model.scannedFoods.remove(at: i)
                                    }
                                }
                                Divider()
                            }
                            Spacer()
                        }
                        .padding()
                        .background(.white)
                    }
                }
            }
        }
        .onChange(of: scannedCode) { oldValue, newValue in
            if newValue == "" { return }
            Task {
                do {
                    canScan = false
                    scannedCode = ""
                    F.vibrate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        F.vibrate()
                    }
                    try await model.addFood(newValue)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [self] in
                        canScan = true
                    }
                } catch {
                    print(error)
                    couldntFind.toggle()
                    scannedCode = ""
                    canScan = true
                }
            }
        }
        .toast(isPresenting: $couldntFind) {
            AlertToast(displayMode: .alert, type: .error(.red), title: "Not found")
        }
        .toast(isPresenting: $isError, alert: {
            AlertToast(displayMode: .alert, type: .error(.red), title: error)
        })
        .toast(isPresenting: $loading, alert: {
            AlertToast(displayMode: .alert, type: .loading)
        })
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Items") {
                    uploadItems()
                }
            }
        })
        .task {
            do {
                try await model.addFood("01364008")
            } catch { print(error) }
        }
    }
    
    func uploadItems() {
        Task {
            do {
                loading = true
                let toUpload = FoodUpload(roomId: roomId, foods: model.scannedFoods)
                let postData = try JSONEncoder().encode(toUpload)
                var request = URLRequest(url: URL(string: K.hostname + "/putInRoom")!,timeoutInterval: Double.infinity)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                request.httpMethod = "POST"
                request.httpBody = postData
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let s = (String(data: data, encoding: .utf8) ?? "")
                print(s)
                if s.contains("false") {
                    error = "Couldn't upload"
                    isError = true
                } else {
                    isShowing = false
                }
                loading = false
            } catch {
                print(error)
                loading = false
                self.error = "Couldn't upload"
                isError = true
            }
        }
    }
}

struct ScannedItemCard: View {
    @Binding var food: Food
    @State var didDelete: ((Food) -> Void)
    
    var body: some View {
        Menu {
            Button(action: {}, label: {
                HStack {
                    Text("Edit")
                    Spacer()
                    Image(systemName: "pencil")
                }
            })
            Button(action: {
                food.increment()
            }, label: {
                HStack {
                    Text("Add")
                    Spacer()
                    Image(systemName: "plus")
                }
            })
            Button(action: {
                food.decrement()
                if food.quantity == 0 { didDelete(food) }
            }, label: {
                HStack {
                    Text("Remove")
                    Spacer()
                    Image(systemName: "minus")
                }
            })
            Button(role: .destructive, action: { didDelete(food) }, label: {
                HStack {
                    Text("Delete")
                    Spacer()
                    Image(systemName: "trash")
                }
                .foregroundStyle(.red)
            })
        } label: {
            ZStack {
                HStack {
                    URLImage(url: food.image) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(10)
                    }
                    Spacer()
                    Text(food.name)
                    Spacer()
                }
                if food.quantity > 1 {
                    VStack {
                        HStack {
                            Spacer()
                            Text(" \(food.quantity) ")
                                .padding(5)
                                .background(.blue)
                                .cornerRadius(20)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .bold()
            .foregroundStyle(.black)
        }
    }
}

#Preview {
    NavigationStack {
        Scanner(isShowing: .constant(true), roomId: .constant(1))
    }
}
