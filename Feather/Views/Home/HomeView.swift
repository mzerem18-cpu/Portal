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

// MARK: - Main Home View (VisionOS / Dark Glass Style)
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
            // MARK: Premium Dark Gradient Background
            LinearGradient(
                colors: [Color.black, Color(UIColor.systemIndigo).opacity(0.15), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            NBNavigationView("Hub") {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        
                        // MARK: - Vision Glass Hero Slider
                        if !featuredApps.isEmpty {
                            TabView {
                                ForEach(featuredApps) { app in
                                    NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                        showDownloadNotification(for: app)
                                    }) {
                                        VisionHeroCard(app: app, downloadManager: downloadManager, onDownloadComplete: {
                                            showDownloadNotification(for: app)
                                        })
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(height: 300)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            .padding(.top, 10)
                        }
                        
                        // MARK: - Glass List Rows
                        VStack(alignment: .leading, spacing: 30) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 15) {
                                    Text(category.uppercased())
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.horizontal, 24)
                                        .tracking(1.5)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 16) {
                                            ForEach(categoryApps) { app in
                                                NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                                    showDownloadNotification(for: app)
                                                }) {
                                                    VisionAppCard(app: app, downloadManager: downloadManager) {
                                                        showDownloadNotification(for: app)
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                }
                            }
                        }
                        
                        Spacer().frame(height: 50)
                    }
                }
                .refreshable { await loadApps() }
            }
            .searchable(text: $searchText, prompt: "Search in Hub...")
            .preferredColorScheme(.dark) // Force Dark Mode for this style
            .onAppear { Task { await loadApps() } }
            
            // Notification
            if showNotification, let app = downloadedApp {
                VisionNotification(app: app)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { self.showNotification = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut) { self.showNotification = false }
        }
    }
    
    private func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ipa.json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([HomeApp].self, from: data)
            await MainActor.run { self.apps = decoded }
        } catch { print("Error: \(error)") }
    }
}

// MARK: - VisionOS UI Components

struct VisionHeroCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: app.fullBannerURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.white.opacity(0.05)
            }
            .frame(width: UIScreen.main.bounds.width - 48, height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            
            // Glass Footer
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(app.category ?? "Featured")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete, style: .glass)
                    .frame(width: 80)
            }
            .padding(20)
            .frame(width: UIScreen.main.bounds.width - 48)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        }
        .padding(.horizontal, 24)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
    }
}

struct VisionAppCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        VStack(spacing: 0) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.white.opacity(0.05)
            }
            .frame(width: 150, height: 120)
            .clipped()
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(app.developer ?? "App")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete, style: .glass)
            }
            .padding(16)
            .frame(width: 150, alignment: .leading)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

struct VisionNotification: View {
    let app: HomeApp
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { Color.white.opacity(0.1) }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Installed Successfully")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(app.name)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            Image(systemName: "sparkles")
                .foregroundColor(.white)
                .font(.title2)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
    }
}

// MARK: - Vision Detail View
struct HomeAppDetailView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack(alignment: .top) {
            // Full Screen Blurred Background
            AsyncImage(url: app.fullBannerURL ?? app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.black
            }
            .ignoresSafeArea()
            .blur(radius: 60)
            .overlay(Color.black.opacity(0.5)) // Darken the blur
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    
                    // Top Nav
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, safeAreaTop() + 10)
                    
                    // App Icon & Title
                    VStack(spacing: 20) {
                        AsyncImage(url: app.fullImageURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.white.opacity(0.1)
                        }
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.4), radius: 30, x: 0, y: 20)
                        
                        VStack(spacing: 8) {
                            Text(app.name)
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(app.developer ?? "AshteMobile")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete, style: .largeGlass)
                            .frame(width: 200)
                            .padding(.top, 10)
                    }
                    
                    // Glass Info Panel
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 0) {
                            GlassStat(title: "Version", value: app.version ?? "1.0")
                            Divider().background(Color.white.opacity(0.2)).frame(height: 40)
                            GlassStat(title: "Size", value: app.size ?? "N/A")
                            Divider().background(Color.white.opacity(0.2)).frame(height: 40)
                            GlassStat(title: "Type", value: app.category ?? "App")
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Features")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            if let hacks = app.hack, !hacks.isEmpty {
                                ForEach(hacks, id: \.self) { hack in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.white)
                                        Text(hack)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            } else {
                                Text("Experience the best of \(app.name). Optimized for your device with seamless performance.")
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineSpacing(6)
                            }
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
            .environment(\.colorScheme, .dark)
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
    }
    
    private func safeAreaTop() -> CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44
    }
}

struct GlassStat: View {
    let title: String; let value: String
    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.6))
            Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(.white).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Downloader & Button
enum ButtonStyleType { case glass, largeGlass }

class HomeAppDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: CGFloat = 0
    @Published var isDownloading = false
    @Published var isFinished = false
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?
    private var downloadURL: URL?
    private var onFinished: ((URL) -> Void)?
    
    func start(url: URL, onFinished: @escaping (URL) -> Void) {
        self.downloadURL = url; self.onFinished = onFinished; self.isDownloading = true; self.progress = 0; self.isFinished = false
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        downloadTask = session?.downloadTask(with: url); downloadTask?.resume()
    }
    
    func stop() { downloadTask?.cancel(); isDownloading = false; progress = 0 }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 { DispatchQueue.main.async { self.progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite) } }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ipa")
        try? FileManager.default.copyItem(at: location, to: dest)
        DispatchQueue.main.async { self.isDownloading = false; self.isFinished = true; self.onFinished?(dest)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { self.isFinished = false } }
        }
    }
}

struct HomeDownloadButtonView: View {
    let app: HomeApp; @ObservedObject var downloadManager: DownloadManager; var onDownloadComplete: () -> Void
    var style: ButtonStyleType
    @StateObject private var downloader = HomeAppDownloader()
    
    var body: some View {
        Group {
            if downloader.isFinished {
                Button(action: {}) {
                    Text("OPEN")
                        .font(.system(size: style == .largeGlass ? 16 : 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, style == .largeGlass ? 14 : 8)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
                .disabled(true)
            } else if downloader.isDownloading {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.2), lineWidth: 3).frame(width: style == .largeGlass ? 36 : 28, height: style == .largeGlass ? 36 : 28)
                    if downloader.progress > 0 {
                        Circle().trim(from: 0, to: downloader.progress)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90)).frame(width: style == .largeGlass ? 36 : 28, height: style == .largeGlass ? 36 : 28)
                    }
                    RoundedRectangle(cornerRadius: 3).fill(Color.white).frame(width: style == .largeGlass ? 12 : 10, height: style == .largeGlass ? 12 : 10)
                        .onTapGesture { downloader.stop() }
                }
                .frame(height: style == .largeGlass ? 48 : 32)
            } else {
                Button(action: {
                    if let url = URL(string: app.url) {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        downloader.start(url: url) { localURL in
                            _ = downloadManager.startDownload(from: localURL)
                            onDownloadComplete()
                        }
                    }
                }) {
                    Text("GET")
                        .font(.system(size: style == .largeGlass ? 16 : 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, style == .largeGlass ? 14 : 8)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }.frame(height: style == .largeGlass ? 48 : 32)
    }
}
