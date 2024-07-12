//
//  Models.swift
//  Pantry Check
//
//  Created by Armaan Ahmed on 7/6/24.
//

import Foundation
import SwiftUI

struct K {
    static let hostname = "https://pantry-check-armaan-crypto-armaancryptos-projects.vercel.app"
//    static let hostname = "http://localhost:3000"
}

struct Food: Codable, Identifiable, Equatable {
    let id: Int
    let foodObjectId: Int
    var name: String
    let upc: String
    var image: String
    let category: String
    var quantity: Int
    
    mutating func increment() {
        quantity += 1
    }
    
    mutating func decrement() {
        quantity -= 1
    }
}

struct FoodUpload: Codable {
    let roomId: Int
    let foods: [Food]
}

struct FoodData: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let upc: String
    let image: String
    let category: String
    
    func toFood() -> Food {
        return Food(id: id, foodObjectId: id, name: name, upc: upc, image: image, category: category, quantity: 1)
    }
}

struct RawRoom: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
}

struct Room: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    var foods: [Food]
}

struct RoomData: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let foods: String
    
    func toRoom() -> Room {
        return Room(id: id, name: name, foods: (try? JSONDecoder().decode([Food].self, from: Data(foods.utf8))) ?? [])
    }
    
    func getFoods() async throws -> [Food] {
        let url = URL(string: K.hostname + "/getFoodFromRoom")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let foods = try? JSONDecoder().decode([Food].self, from: data)
        return foods ?? []
    }
}

struct F {
    static func vibrate(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let impactMed = UIImpactFeedbackGenerator(style: style)
        impactMed.impactOccurred()
    }
}
