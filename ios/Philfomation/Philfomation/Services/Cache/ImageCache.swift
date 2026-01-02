//
//  ImageCache.swift
//  Philfomation
//

import SwiftUI
import UIKit

// MARK: - Image Cache Manager

final class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxMemoryCacheSize = 50 // Number of images
    private let maxDiskCacheSize: Int64 = 100 * 1024 * 1024 // 100MB

    private init() {
        // Setup memory cache
        memoryCache.countLimit = maxMemoryCacheSize

        // Setup disk cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    // MARK: - Public Methods

    func image(for url: String) -> UIImage? {
        let key = cacheKey(for: url)

        // Check memory cache first
        if let memoryImage = memoryCache.object(forKey: key as NSString) {
            return memoryImage
        }

        // Check disk cache
        if let diskImage = loadFromDisk(key: key) {
            // Store in memory cache for faster access
            memoryCache.setObject(diskImage, forKey: key as NSString)
            return diskImage
        }

        return nil
    }

    func setImage(_ image: UIImage, for url: String) {
        let key = cacheKey(for: url)

        // Store in memory cache
        memoryCache.setObject(image, forKey: key as NSString)

        // Store in disk cache asynchronously
        Task.detached(priority: .background) { [weak self] in
            self?.saveToDisk(image: image, key: key)
        }
    }

    func loadImage(from url: String) async -> UIImage? {
        // Check cache first
        if let cached = image(for: url) {
            return cached
        }

        // Download image
        guard let imageURL = URL(string: url) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: imageURL)

            // Verify response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                return nil
            }

            // Cache the image
            setImage(image, for: url)

            return image
        } catch {
            print("Failed to download image: \(error)")
            return nil
        }
    }

    @objc func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    func clearAllCache() async {
        clearMemoryCache()

        // Clear disk cache
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func cacheSize() -> Int64 {
        var size: Int64 = 0
        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        return size
    }

    // MARK: - Prefetching

    func prefetchImages(urls: [String]) {
        Task.detached(priority: .background) { [weak self] in
            for url in urls {
                guard self?.image(for: url) == nil else { continue }
                _ = await self?.loadImage(from: url)
            }
        }
    }

    // MARK: - Private Methods

    private func cacheKey(for url: String) -> String {
        // Create a hash for the URL to use as filename
        url.data(using: .utf8)?.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-") ?? url
    }

    private func diskCachePath(for key: String) -> URL {
        cacheDirectory.appendingPathComponent(key)
    }

    private func loadFromDisk(key: String) -> UIImage? {
        let path = diskCachePath(for: key)
        guard let data = try? Data(contentsOf: path),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    private func saveToDisk(image: UIImage, key: String) {
        let path = diskCachePath(for: key)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: path)

        // Check disk cache size and cleanup if needed
        cleanupDiskCacheIfNeeded()
    }

    private func cleanupDiskCacheIfNeeded() {
        let currentSize = cacheSize()
        guard currentSize > maxDiskCacheSize else { return }

        // Get all cached files sorted by modification date
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else { return }

        var files: [(url: URL, date: Date, size: Int64)] = []

        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
               let date = values.contentModificationDate,
               let size = values.fileSize {
                files.append((fileURL, date, Int64(size)))
            }
        }

        // Sort by date (oldest first)
        files.sort { $0.date < $1.date }

        // Remove oldest files until under limit
        var removedSize: Int64 = 0
        let targetRemoval = currentSize - maxDiskCacheSize / 2 // Remove to half capacity

        for file in files {
            guard removedSize < targetRemoval else { break }
            try? fileManager.removeItem(at: file.url)
            removedSize += file.size
        }
    }
}

// MARK: - Legacy Actor-based Cache (for backward compatibility)

actor ImageCache {
    static let shared = ImageCache()

    private init() {}

    func image(for url: String) -> Image? {
        if let uiImage = ImageCacheManager.shared.image(for: url) {
            return Image(uiImage: uiImage)
        }
        return nil
    }

    func setImage(_ image: Image, for url: String) {
        // This method is deprecated - use ImageCacheManager directly
    }

    func clearCache() {
        Task {
            await ImageCacheManager.shared.clearAllCache()
        }
    }
}

// MARK: - Cached Async Image View

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var loadedImage: UIImage?
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
            if let image = loadedImage {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .task(id: url) {
                        await loadImage()
                    }
            }
        }
    }

    private func loadImage() async {
        guard let urlString = url, !isLoading else { return }

        isLoading = true

        // Check cache first
        if let cached = ImageCacheManager.shared.image(for: urlString) {
            loadedImage = cached
            isLoading = false
            return
        }

        // Load from network
        if let image = await ImageCacheManager.shared.loadImage(from: urlString) {
            await MainActor.run {
                loadedImage = image
            }
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

// MARK: - Thumbnail Image View (optimized for lists)

struct ThumbnailImage: View {
    let url: String?
    let size: CGSize
    let cornerRadius: CGFloat
    let placeholder: AnyView

    @State private var image: UIImage?

    init(
        url: String?,
        size: CGSize,
        cornerRadius: CGFloat = 8,
        @ViewBuilder placeholder: () -> some View = { Color(.systemGray5) }
    ) {
        self.url = url
        self.size = size
        self.cornerRadius = cornerRadius
        self.placeholder = AnyView(placeholder())
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
                    .task(id: url) {
                        await loadThumbnail()
                    }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func loadThumbnail() async {
        guard let urlString = url else { return }

        if let loaded = await ImageCacheManager.shared.loadImage(from: urlString) {
            // Downscale for thumbnail
            let scale = UIScreen.main.scale
            let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
            let thumbnail = loaded.preparingThumbnail(of: targetSize) ?? loaded

            await MainActor.run {
                image = thumbnail
            }
        }
    }
}
