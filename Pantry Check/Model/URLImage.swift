//
//  URLImage.swift
//  Year Social
//
//  Created by Armaan Ahmed on 6/5/24.
//

import Foundation
import SwiftUI
import CachedAsyncImage

struct URLImage: View {
    
    @State var url: String
    @State var imageConfig: ((Image) -> any View)
    @StateObject private var viewModel = AsyncImageViewModel()
    @State var imgUrl = ""
    @State var loaded = false
    
    let localImages = ["default"]

    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: url)) { image in
                AnyView(imageConfig(image))
            } placeholder: {
                AnyView(imageConfig(Image("fill")))
            }

//            if let image = viewModel.image {
//                AnyView(imageConfig(Image(uiImage: image)))
//            } else if viewModel.isLoading {
//                AnyView(imageConfig(Image(uiImage: .fill)))
//            } else {
//                if !loaded {
//                    ProgressView() // TODO: replace with a placeholder
//                        .onAppear(perform: {
//                            viewModel.loadImage(from: imgUrl)
//                            loaded = true
//                        })
//                }
//            }
        }
        .onAppear(perform: {
            imgUrl = url
            
        })
        .onChange(of: url) { oldValue, newValue in
            imgUrl = url
            viewModel.loadImage(from: imgUrl)
            
        }
//        VStack {
//            if localImages.contains(url) {
//                if let d = UserDefaults.standard.data(forKey: url), let image = UIImage(data: d) {
//                    AnyView(imageConfig(Image(uiImage: image)))
//                } else {
//                    EmptyView()
//                }
//            } else {
//                CachedAsyncImage(url: URL(string: url)) { image in
//                    AnyView(imageConfig(image))
//                } placeholder: {
//                    EmptyView()
//                }
//            }
//        }
    }
}

class AsyncImageViewModel: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var isLoading = false
    @Published var error: Error? = nil
    @Published var hasError = false

    func loadImage(from u: String) {
        if let d = UserDefaults.standard.data(forKey: u) {
            DispatchQueue.main.async { self.image = UIImage(data: d) }
            return
        }
        isLoading = true
        if !u.hasPrefix("http") {
            guard let data = Data(base64Encoded: u) else { return }
            UserDefaults.standard.setValue(data, forKey: u)
            DispatchQueue.main.async { self.image = UIImage(data: data) }
            return
        }
        guard let url = URL(string: u) else { isLoading = false; return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                UserDefaults.standard.setValue(data, forKey: url.absoluteString)
                DispatchQueue.main.async { self.image = UIImage(data: data) }
                isLoading = false
            } catch {
                self.error = error
                hasError = true
                isLoading = false
            }
        }
    }
}
