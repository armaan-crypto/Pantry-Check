//
//  FoodDetails.swift
//  Pantry Check
//
//  Created by Armaan Ahmed on 7/8/24.
//

import SwiftUI
import AlertToast

struct FoodDetails: View {
    
    @Binding var food: Food
    @State var isEditing = false
    @State var name = ""
    @State var takePicture = false
    @State var image = UIImage(named: "fill")!
    @State var rooms: [Room]
    @State var selectedRoom: Int
    @Environment(\.presentationMode) var presentationMode
    @State var loading = false
    @State var isError = false
    
    var body: some View {
        ZStack {
            if !isEditing {
                ScrollView {
                    VStack(spacing: 20) {
                        URLImage(url: food.image) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width, height: 400)
                                .clipped()
                        }
//                        Text(food.name)
//                            .font(.system(size: 24, weight: .bold))
//                        Text("Quantity: \(food.quantity)")
//                            .font(.system(size: 20))
                        List {
                            HStack(spacing: 20) {
                                Text("Name")
                                    .bold()
                                Spacer()
                                Text(food.name)
                            }
                            HStack(spacing: 20) {
                                Text("Quantity")
                                    .bold()
                                Spacer()
                                Text("\(food.quantity)")
                            }
                            HStack(spacing: 20) {
                                Text("Barcode")
                                    .bold()
                                Spacer()
                                Text(food.upc)
                            }
                            HStack(spacing: 20) {
                                Text("Element ID")
                                    .bold()
                                Spacer()
                                Text("\(food.id)")
                            }
                        }
                        .scrollDisabled(true)
                        .frame(height: 300)
                        Spacer()
                    }
                }
                VStack {
                    Spacer()
                    HStack(spacing: 30) {
                        Button {
                            changeQuantity(change: 0)
                        } label: {
                            Image(systemName: "trash")
                                .scaleEffect(1.3)
                        }
                        Spacer()
                        Button {
                            changeQuantity(change: -1)
                        } label: {
                            Image(systemName: "minus")
                                .scaleEffect(1.3)
                        }
                        Button {
                            changeQuantity(change: 1)
                        } label: {
                            Image(systemName: "plus")
                                .scaleEffect(1.3)
                        }
                    }
                    .padding().padding()
                    .frame(width: UIScreen.main.bounds.width, height: 40)
                    .background(Color(uiColor: .systemGray6))
                    .foregroundStyle(.black)
                }
            } else {
                Form {
                    Section("Name") {
                        TextField("Name", text: $name)
                    }
                    Section("Room") {
                        Picker("Room", selection: $selectedRoom) {
                            ForEach(rooms) { room in
                                Text(room.name)
                                    .tag(room.id)
                            }
                        }

                    }
                }
            }
        }
        .background(.background.secondary)
        .onAppear(perform: {
            name = food.name
        })
        .navigationTitle(food.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if !isEditing {
                        withAnimation {
                            isEditing.toggle()
                        }
                    } else {
                        updateFoodToServer()
                    }
                }
            }
        })
        .fullScreenCover(isPresented: $takePicture, content: {
            CameraPicker(selectedImage: $image)
        })
        .toast(isPresenting: $loading) {
            AlertToast(displayMode: .alert, type: .loading)
        }
        .toast(isPresenting: $isError) {
            AlertToast(displayMode: .alert, type: .error(.red), title: "Couldn't upload")
        }
    }
    
    func updateFoodToServer() {
        Task {
            do {
                loading = true
                food.name = name
//                food.image = getImageDataString() ?? "default"
                let toUpdate = UpdateFoodData(id: food.id, foodObjectId: food.foodObjectId, name: name, image: food.image, roomId: selectedRoom, quantity: food.quantity)
                try await sendUpdate(toUpdate: toUpdate)
                loading = false
                isEditing = false
            } catch {
                print(error)
                loading = false
                isError = true
            }
        }
    }
    
    func changeQuantity(change: Int) {
        Task {
            do {
                loading = true
                var toUpdate = UpdateFoodData(id: food.id, foodObjectId: food.foodObjectId, name: food.name, image: food.image, roomId: selectedRoom, quantity: food.quantity)
                if change == 0 {
                    food.quantity = 0
                    toUpdate.quantity = 0
                } else {
                    food.quantity += change
                    toUpdate.quantity += change
                }
                try await sendUpdate(toUpdate: toUpdate)
                DispatchQueue.main.async { [self] in
                    if food.quantity == 0 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                loading = false
            } catch {
                print(error)
                loading = false
                isError = true
            }
        }
    }
    
    func sendUpdate(toUpdate: UpdateFoodData) async throws {
        let postData = try JSONEncoder().encode(toUpdate)
        var request = URLRequest(url: URL(string: K.hostname + "/updateFood")!,timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let (_, _) = try await URLSession.shared.data(for: request)
//        print(String(data: data, encoding: .utf8))
    }
    
    func getImageDataString() -> String? {
        guard let d = image.jpegData(compressionQuality: 0.5) else { return nil }
        return d.base64EncodedString()
    }
    
    struct UpdateFoodData: Codable {
        let id: Int
        let foodObjectId: Int
        let name: String
        let image: String
        let roomId: Int
        var quantity: Int
    }
}

#Preview {
    NavigationStack {
        FoodDetails(food: .constant(Food(id: 1, foodObjectId: 1, name: "Food", upc: "12345", image: "https://images.openfoodfacts.org/images/products/001/410/008/6079/front_en.16.400.jpg", category: "", quantity: 1)), rooms: [Room(id: 1, name: "Uncategorized", foods: [])], selectedRoom: 1)
    }
}
/*
Section("Image") {
    ZStack {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(height: 350)
            .cornerRadius(20)
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "pencil")
                    .padding(5)
                    .background(.black)
                    .foregroundColor(.white)
                    .cornerRadius(100)
            }
        }
        .padding()
        .padding(8)
    }
    .onTapGesture {
        takePicture = true
    }
}
*/
