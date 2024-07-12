//
//  Home.swift
//  Pantry Check
//
//  Created by Armaan Ahmed on 7/6/24.
//

import SwiftUI

class HomePageModel: ObservableObject {
    
    @Published var toShow: [Room] = []
    
    @Published var rooms: [Room] = []
    @Published var categories: [Room] = []
    @Published var showingRooms = true
    
    func load() async throws {
        try await loadRooms()
    }
    
    func showRooms() {
        showingRooms = true
        toShow = rooms
    }
    func showCategories() {
        print(categories)
        showingRooms = false
        toShow = categories
    }
    
    func loadRooms() async throws {
        let url = URL(string: K.hostname + "/getRoomsWithFoods")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let r = (try JSONDecoder().decode([RoomData].self, from: data))
        DispatchQueue.main.async { [self] in
            rooms = [Room(id: 1, name: "Name", foods: [Food(id: 0, foodObjectId: 0, name: "", upc: "", image: "", category: "", quantity: 0)])]
            rooms = []
            categories = []
            for room in r {
                let newRoom = room.toRoom()
                for f in newRoom.foods {
                    if categories.contains(where: { $0.name == f.category }) {
                        let i = categories.firstIndex(where: { $0.name == f.category })!
                        categories[i].foods.append(f)
                    } else {
                        categories.append(Room(id: abs(UUID().hashValue) * -1, name: f.category, foods: [f]))
                    }
                }
                rooms.append(newRoom)
            }
            if showingRooms {
                toShow = rooms
            } else {
                toShow = categories
            }
        }
    }
    
    func reload() async throws {
        let url = URL(string: K.hostname + "/getRoomsWithFoods")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let r = (try JSONDecoder().decode([RoomData].self, from: data))
        DispatchQueue.main.async { [self] in
            rooms = []
            categories = []
            for room in r {
                let newRoom = room.toRoom()
                for f in newRoom.foods {
                    if categories.contains(where: { $0.name == f.category }) {
                        let i = categories.firstIndex(where: { $0.name == f.category })!
                        categories[i].foods.append(f)
                    } else {
                        categories.append(Room(id: abs(UUID().hashValue) * -1, name: f.category, foods: [f]))
                    }
                }
                rooms.append(newRoom)
            }
            if showingRooms {
                toShow = rooms
            } else {
                toShow = categories
            }
        }
    }
}

struct Home: View {
    
    @StateObject var model = HomePageModel()
    @State var searched = ""
    let layout = [
        GridItem(.flexible(minimum: 40)),
        GridItem(.flexible(minimum: 40)),
        GridItem(.flexible(minimum: 40)),
        GridItem(.flexible(minimum: 40))
    ]
    @State var showScanner = false
    
    @State var isFiltering = false
    @State var filter = 0
    @State var selectedRoomId = 0
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: layout, pinnedViews: [.sectionHeaders]) {
                ForEach(model.toShow) { room in
                    if !isFiltering || filter == room.id {
                        Section {
                            ForEach(room.foods) { food in
                                if searched == "" || food.name.lowercased().contains(searched.lowercased()) {
                                    FoodCard(model: model, room: room, food: food)
                                }
                            }
                        } header: {
                            VStack {
                                Divider()
                                HStack {
                                    Text(room.name)
                                    Spacer()
                                    Text("\(room.foods.count)")
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                Divider()
                            }
                            .background(.blue)
                            .foregroundColor(.white)
                            .bold()
                        }
                    }
                }
            }
        }
        .task {
            do {
                try await model.load()
            } catch {
                print(error)
            }
        }
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searched)
        .refreshable {
            try? await model.reload()
        }
        .fullScreenCover(isPresented: $showScanner, onDismiss: {
            Task {
                try? await model.reload()
            }
        }, content: {
            NavigationStack {
                Scanner(isShowing: $showScanner, roomId: $selectedRoomId)
                    .toolbar(content: {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") {
                                showScanner = false
                            }
                        }
                    })
            }
        })
        .onChange(of: filter, { oldValue, newValue in
            withAnimation {
                isFiltering = (filter != 0 && filter != -1)
                if filter < 0 { model.showCategories() }
                else { model.showRooms() }
            }
        })
        .toolbar(content: myToolbar)
    }
    
    @ToolbarContentBuilder
    func myToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack {
                Menu {
                    ForEach(model.rooms) { room in
                        Button(room.name) {
                            selectedRoomId = room.id
                            showScanner = true
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker(selection: $filter) {
                    Text("All Rooms")
                    .tag(0)
                    ForEach(model.rooms) { room in
                        Text(room.name)
                            .tag(room.id)
                    }
                    Divider()
                    Text("All Categories")
                    .tag(-1)
                    ForEach(model.categories) { room in
                        Text(room.name)
                        .tag(room.id)
                    }
                } label: {
                    EmptyView()
                }
                NavigationLink("Edit...") {
                   EditRooms()
                }
            } label: {
                Image(systemName: "list.bullet")
            }
        }
    }
}

struct FoodCard: View {
    
    @State var model: HomePageModel
    @State var room: Room
    @State var food: Food
    
    var body: some View {
        NavigationLink {
            FoodDetails(food: $food, rooms: model.rooms, selectedRoom: room.id)
                .foregroundStyle(.black)
        } label: {
            ZStack {
                VStack {
                    URLImage(url: food.image) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width / 4, height: 100)
                            .clipped()
                    }
                    .padding(.top, 5)
                    Spacer()
                    Text(food.name)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 5)
                    Spacer()
                }
                if food.quantity != 1 {
                    VStack {
                        HStack {
                            Spacer()
                            Text(" \(food.quantity) ")
                                .padding(5)
                                .background(.blue)
                                .cornerRadius(20)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(10)
                }
            }
            .background(.white)
    //        .cornerRadius(10)
            .border(Color.init(uiColor: .systemGray4))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        Home()
    }
}
