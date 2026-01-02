//
//  ImageCache.swift
//  Philfomation
//

import SwiftUI

actor ImageCache {
    static let shared = ImageCache()

    private var cache: [String: Image] = [:]
    private let maxCacheSize = 100

    private init() {}

    func image(for url: String) -> Image? {
        cache[url]
    }

    func setImage(_ image: Image, for url: String) {
        if cache.count >= maxCacheSize {
            // Remove oldest entries
            let keysToRemove = Array(cache.keys.prefix(maxCacheSize / 4))
            keysToRemove.forEach { cache.removeValue(forKey: $0) }
        }
        cache[url] = image
    }

    func clearCache() {
        cache.removeAll()
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var cachedImage: Image?
    @State private var isLoading = false

    init(
        url: String?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = cachedImage {
                content(image)
            } else {
                placeholder()
                    .task {
                        await loadImage()
                    }
            }
        }
    }

    private func loadImage() async {
        guard let urlString = url, let url = URL(string: urlString) else { return }

        // Check cache first
        if let cached = await ImageCache.shared.image(for: urlString) {
            cachedImage = cached
            return
        }

        guard !isLoading else { return }
        isLoading = true

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                let image = Image(uiImage: uiImage)
                await ImageCache.shared.setImage(image, for: urlString)
                await MainActor.run {
                    cachedImage = image
                }
            }
        } catch {
            print("Failed to load image: \(error)")
        }

        isLoading = false
    }
}

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: String?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.init(url: url, content: content) {
            ProgressView()
        }
    }
}
