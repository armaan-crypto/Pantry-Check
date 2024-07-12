//
//  EditRooms.swift
//  Pantry Check
//
//  Created by Armaan Ahmed on 7/8/24.
//

import SwiftUI
import AlertToast

class EditRoomsModel: ObservableObject {
    @Published var rooms: [RawRoom] = []
    
    func loadRooms() async throws {
        let url = URL(string: K.hostname + "/getRooms")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let r = try JSONDecoder().decode([RawRoom].self, from: data)
        DispatchQueue.main.async { self.rooms = r }
    }
    
    func remove(room: RawRoom) async throws {
        guard let i = rooms.firstIndex(of: room) else { return }
        rooms.remove(at: i)
        let url = URL(string: K.hostname + "/removeRoom?id=\(room.id)")!
        let (_, _) = try await URLSession.shared.data(from: url)
    }
    
    func add(roomName: String) async throws {
        let url = URL(string: K.hostname + "/addRoom?name=" + roomName)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let room = try JSONDecoder().decode(RawRoom.self, from: data)
        withAnimation { DispatchQueue.main.async { self.rooms.append(room) } }
    }
}

struct EditRooms: View {
    
    @StateObject var model = EditRoomsModel()
    @State var addRoom = false
    @State var loading = false
    @State var isError = false
    @State var error = ""
    
    var body: some View {
        List {
            ForEach(model.rooms) { room in
                HStack {
                    Text(room.name)
                    Spacer()
                    if room.id != 1 {
                        Menu {
                            Button("Remove") {
                                remove(room: room)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .task {
            do {
                try await model.loadRooms()
            } catch {
                print(error)
            }
        }
        .navigationTitle("Rooms")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    addRoom = true
                }, label: {
                    Image(systemName: "plus")
                })
            }
        })
        .sheet(isPresented: $addRoom, content: {
            AddRoom { roomName in
                Task {
                    do {
                        addRoom = false
                        loading = true
                        try await model.add(roomName: roomName)
                        loading = false
                    } catch {
                        print(error)
                        self.error = "Couldn't add"
                        isError = true
                        loading = false
                    }
                }
            }
                .presentationDetents([.fraction(0.2), .large])
        })
        .toast(isPresenting: $loading) {
            AlertToast(displayMode: .alert, type: .loading)
        }
        .toast(isPresenting: $isError) {
            AlertToast(displayMode: .alert, type: .error(.red), title: error)
        }
    }
    
    func remove(room: RawRoom) {
        Task {
            do {
                try await model.remove(room: room)
            } catch {
                print(error)
            }
        }
    }
}

struct AddRoom: View {
    @State var roomName = ""
    @State var onTap: ((String) -> Void)
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Room Name", text: $roomName)
            }
            .navigationTitle("Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        onTap(roomName)
                    }
                }
            })
        }
    }
}

#Preview {
    NavigationStack {
        EditRooms()
    }
}
