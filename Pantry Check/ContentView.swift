//
//  ContentView.swift
//  Pantry Check
//
//  Created by Armaan Ahmed on 7/6/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            Home()
                .onAppear(perform: {
//                    resetDefaults()
                    if UserDefaults.standard.value(forKey: "default") == nil {
                        let d = UIImage(named: "fill")?.jpegData(compressionQuality: 1.0)
                        UserDefaults.standard.setValue(d, forKey: "default")
                    }
                })
        }
    }
    
    func resetDefaults() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
    }
}

#Preview {
    ContentView()
}
