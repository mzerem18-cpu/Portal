//
//  HomeView.swift
//  Feather
//

import SwiftUI
import NimbleViews
import Foundation
import UIKit

// MARK: - Models
struct HomeApp: Codable, Identifiable {
    var id: String { url }
    let name: String
    let version: String?
    let category: String?
    let image: String?
    let size: String?
    let developer: String?
    let bundle: String?
    let url: String
    let status: String?
    let banner: String?
    let hack: [String]?

    var fullImageURL: URL? {
        guard let img = image else { return nil }
        return URL(string: "https://ashtemobile.tututweak.com/\(img)")
    }
    
    var fullBannerURL: URL? {
        if let ban = banner {
            return URL(string: "https://ashtemobile.tututweak.com/\(ban)")
        }
        return fullImageURL
    }
}

// MARK: - Main Home View
struct HomeView: View {
    @StateObject var downloadManager = DownloadManager.shared
    @State private var apps: [HomeApp] = []
    
    @State private var showNotification = false
    @State private var downloadedApp: HomeApp? = nil
    @State private var searchText = ""
    
    var featuredApps: [HomeApp] {
        Array(apps.filter { $0.status == "new" || $0.status == "top" || $0.status == "update" }.prefix(5))
    }
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            NBNavigationView("Home") {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        
                        // Featured Slider (Modernized)
                        if !featuredApps.isEmpty {
                            TabView {
                                ForEach(featuredApps) { app in
                                    NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                        showDownloadNotification(for: app)
                                    }) {
                                        FeaturedAppView(app: app, downloadManager: downloadManager) {
                                            showDownloadNotification(for: app)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(height: 300)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            .padding(.top, 10)
                        }
                        
                        // Categories and App Cards (Modernized)
                        VStack(alignment: .leading, spacing: 28) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(category)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                        Spacer()
                                        Text("See All")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 18) {
                                            ForEach(categoryApps) { app in
                                                NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                                    showDownloadNotification(for: app)
                                                }) {
                                                    HomeAppCardView(app: app, downloadManager: downloadManager) {
                                                        showDownloadNotification(for: app)
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 5)
                                    }
                                }
                            }
                        }
                        
                        SocialMediaFooter()
                            .padding(.top, 15)
                            .padding(.bottom, 40)
                    }
                }
                .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
                .refreshable {
                    await loadApps()
                }
            }
            .searchable(text: $searchText, prompt: "Search apps...")
            .onAppear {
                Task { await loadApps() }
            }
            
            // Notification Banner
            if showNotification, let app = downloadedApp {
                notificationBanner(for: app)
                    .padding(.top, 8)
                    .zIndex(100)
            }
        }
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            self.showNotification = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.easeOut) {
                self.showNotification = false
            }
        }
    }
    
    @ViewBuilder
    private func notificationBanner(for app: HomeApp) -> some View {
        HStack(alignment: .center, spacing: 12) {
            AsyncImage(url: URL(string: "https://ashtemobile.tututweak.com/a.png")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.black
            }
            .frame(width: 45, height: 45)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Ready to Install")
                    .font(.system(size: 15, weight: .bold))
                Text("\(app.name) is ready in Library.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ipa.json") else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode([HomeApp].self, from: data)
            DispatchQueue.main.async {
                self.apps = decoded
            }
        } catch {
            print("Error loading: \(error)")
        }
    }
}

// MARK: - Detail View (Modernized)
struct HomeAppDetailView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                
                GeometryReader { proxy in
                    let minY = proxy.frame(in: .global).minY
                    let isScrolledDown = minY > 0
                    let height = isScrolledDown ? 280 + minY : 280
                    let offset = isScrolledDown ? -minY : 0

                    ZStack(alignment: .top) {
                        AsyncImage(url: app.fullImageURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.blue.opacity(0.3)
                        }
                        .frame(width: proxy.size.width, height: height)
                        .clipped()
                        .blur(radius: 50)
                        .overlay(Color.black.opacity(0.2))
                        .offset(y: offset)
                        
                        HStack {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            Spacer()
                            
                            Button(action: {
                                let shareText = "Download \(app.name) from AshteMobile Store!\nhttps://t.me/ashtemmobile"
                                let av = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                                UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, safeAreaTop() + 10)
                    }
                }
                .frame(height: 280)
                
                HStack(alignment: .top, spacing: 16) {
                    AsyncImage(url: app.fullImageURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(app.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if let hacks = app.hack, !hacks.isEmpty {
                            Text(hacks[0])
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text(app.category ?? "App")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                            .frame(width: 90, alignment: .leading)
                            .padding(.top, 8)
                    }
                    .padding(.top, 50)
                }
                .padding(.horizontal, 20)
                .offset(y: -70)
                .padding(.bottom, -50)
                
                // Tags
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "tag.fill").foregroundColor(.blue).font(.system(size: 14))
                        Text(app.version ?? "1.0").font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    HStack {
                        Image(systemName: "shippingbox.fill").foregroundColor(.purple).font(.system(size: 14))
                        Text(app.size ?? "Unknown").font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("Description")
                        .font(.title3.bold())
                    
                    if let hacks = app.hack, !hacks.isEmpty {
                        ForEach(hacks, id: \.self) { hack in
                            Text("• \(hack)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Download \(app.name) now and enjoy smooth performance and regular updates directly from the AshteMobile Store.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Information")
                        .font(.title3.bold())
                        .padding(.bottom, 4)
                    
                    VStack(spacing: 16) {
                        AppInfoRow(title: "Source", value: "AshteMobile Repo")
                        AppInfoRow(title: "Developer", value: app.developer ?? "Unknown")
                        AppInfoRow(title: "Size", value: app.size ?? "Unknown")
                        AppInfoRow(title: "Version", value: app.version ?? "1.0")
                        AppInfoRow(title: "Identifier", value: app.bundle ?? "com.ashte.\(app.name.replacingOccurrences(of: " ", with: "").lowercased())")
                    }
                    .padding(20)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
    }
    
    private func safeAreaTop() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        return window?.safeAreaInsets.top ?? 44
    }
}

struct AppInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
            }
            Divider()
        }
    }
}

// MARK: - Cards
struct FeaturedAppView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: app.fullBannerURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.blue.opacity(0.1)
            }
            .frame(width: UIScreen.main.bounds.width - 40, height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            
            // Gradient Overlay
            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    if let status = app.status {
                        Text(status.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    
                    Text(app.name)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(app.category ?? "App")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                
                HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .padding(25)
        }
        .padding(.horizontal, 20)
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
    }
}

struct HomeAppCardView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(app.category ?? "App")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
        }
        .frame(width: 120)
    }
}

// MARK: - Footer & Socials
struct SocialMediaFooter: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Follow Us")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 25) {
                SocialButton(icon: "paperplane.fill", color: .blue, url: "https://t.me/ashtemobile")
                SocialButton(icon: "camera.fill", color: Color(UIColor.systemPurple), url: "https://www.instagram.com/ashtemobile")
                SocialButton(icon: "play.tv.fill", color: .black, url: "https://www.tiktok.com/@ashtemobile")
                SocialButton(icon: "camera.viewfinder", color: .yellow, url: "https://www.snapchat.com/add/ashtemmobile")
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color(UIColor.secondarySystemGroupedBackground)))
        .padding(.horizontal, 20)
    }
}

struct SocialButton: View {
    let icon: String
    let color: Color
    let url: String
    
    var body: some View {
        Button(action: {
            if let link = URL(string: url) {
                UIApplication.shared.open(link)
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 54, height: 54)
                .background(color.gradient)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Downloader Logic
class HomeAppDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: CGFloat = 0
    @Published var isDownloading = false
    @Published var isFinished = false
    
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?
    private var downloadURL: URL?
    private var onFinished: ((URL) -> Void)?
    
    func start(url: URL, onFinished: @escaping (URL) -> Void) {
        self.downloadURL = url
        self.onFinished = onFinished
        self.isDownloading = true
        self.progress = 0
        self.isFinished = false
        
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        downloadTask = session?.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func stop() {
        downloadTask?.cancel()
        session?.invalidateAndCancel()
        self.isDownloading = false
        self.progress = 0
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            DispatchQueue.main.async {
                self.progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(UUID().uuidString)-\(downloadURL?.lastPathComponent ?? "app.ipa")"
        let destinationURL = tempDir.appendingPathComponent(fileName)
        
        try? FileManager.default.removeItem(at: destinationURL)
        do {
            try FileManager.default.copyItem(at: location, to: destinationURL)
            DispatchQueue.main.async {
                self.isDownloading = false
                self.isFinished = true
                self.onFinished?(destinationURL)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isFinished = false
                    }
                }
            }
        } catch {
            DispatchQueue.main.async { self.isDownloading = false }
        }
        session.finishTasksAndInvalidate()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            DispatchQueue.main.async { self.isDownloading = false }
        }
        session.finishTasksAndInvalidate()
    }
}

// MARK: - Download Button
struct HomeDownloadButtonView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    @StateObject private var downloader = HomeAppDownloader()
    
    var body: some View {
        ZStack {
            if downloader.isFinished {
                Button(action: {}) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .disabled(true)
            } else if downloader.isDownloading {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        .frame(width: 28, height: 28)
                    
                    if downloader.progress > 0 {
                        Circle()
                            .trim(from: 0, to: downloader.progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 28, height: 28)
                            .animation(.linear(duration: 0.2), value: downloader.progress)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    }
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .onTapGesture {
                            downloader.stop()
                        }
                }
                .frame(height: 32)
            } else {
                Button(action: {
                    if let downloadURL = URL(string: app.url) {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        downloader.start(url: downloadURL) { localURL in
                            _ = downloadManager.startDownload(from: localURL)
                            DispatchQueue.main.async {
                                onDownloadComplete()
                            }
                        }
                    }
                }) {
                    Text("Get")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain) 
            }
        }
        .frame(height: 32)
    }
}
