//
//  HomeView.swift
//  Feather
//

import SwiftUI
import NimbleViews
import Foundation
import UIKit

// MARK: - App Model
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
    
    var featuredApps: [HomeApp] {
        Array(apps.filter { $0.status == "new" || $0.status == "top" || $0.status == "update" }.prefix(3))
    }
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            NBNavigationView("Home") {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 35) {
                        
                        // MARK: - Hero Featured Section
                        if !featuredApps.isEmpty {
                            TabView {
                                ForEach(featuredApps) { app in
                                    NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                        showDownloadNotification(for: app)
                                    }) {
                                        ModernHeroCard(app: app, downloadManager: downloadManager) {
                                            showDownloadNotification(for: app)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(height: 280)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            .padding(.top, 10)
                        }
                        
                        // MARK: - Categorized Sections
                        VStack(alignment: .leading, spacing: 30) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 18) {
                                    HStack {
                                        Text(category)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                        Spacer()
                                        Text("See All")
                                            .font(.subheadline).foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 22)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 20) {
                                            ForEach(categoryApps) { app in
                                                NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                                    showDownloadNotification(for: app)
                                                }) {
                                                    PremiumAppCard(app: app, downloadManager: downloadManager) {
                                                        showDownloadNotification(for: app)
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 22)
                                    }
                                }
                            }
                        }
                        
                        SocialMediaFooter()
                            .padding(.bottom, 100)
                    }
                }
                .refreshable { await loadApps() }
            }
            .onAppear { Task { await loadApps() } }
            
            // Success Notification
            if showNotification, let app = downloadedApp {
                ModernNotificationBanner(app: app)
                    .zIndex(100)
            }
        }
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { self.showNotification = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation { self.showNotification = false }
        }
    }
    
    private func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ipa.json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([HomeApp].self, from: data)
            DispatchQueue.main.async { self.apps = decoded }
        } catch { print("Error: \(error)") }
    }
}

// MARK: - Modern UI Components

struct ModernHeroCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: app.fullBannerURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { Color.gray.opacity(0.1) }
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            
            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            
            VStack(alignment: .leading, spacing: 5) {
                Text(app.status?.uppercased() ?? "NEW")
                    .font(.caption2.bold())
                    .foregroundColor(.white.opacity(0.8))
                
                Text(app.name)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text(app.category ?? "Featured")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(25)
        }
        .padding(.horizontal, 22)
        .shadow(color: Color.black.opacity(0.1), radius: 20, y: 10)
    }
}

struct PremiumAppCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: app.fullImageURL)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 10, y: 5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                
                Text(app.category ?? "App")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
        }
        .frame(width: 100)
    }
}

struct ModernNotificationBanner: View {
    let app: HomeApp
    var body: some View {
        HStack(spacing: 15) {
            AsyncImage(url: app.fullImageURL).frame(width: 40, height: 40).clipShape(Circle())
            VStack(alignment: .leading) {
                Text("Installed Successfully").font(.subheadline.bold())
                Text(app.name).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        }
        .padding()
        .background(BlurView(style: .systemThinMaterial))
        .clipShape(Capsule())
        .padding(.top, 50)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Detail View & Helper Components
struct HomeAppDetailView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header Image
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: app.fullImageURL)
                        .frame(maxWidth: .infinity).frame(height: 350).clipped().blur(radius: 50).opacity(0.3)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left").font(.title3.bold()).foregroundColor(.primary)
                                .padding(12).background(Circle().fill(.ultraThinMaterial))
                        }
                        
                        HStack(spacing: 20) {
                            AsyncImage(url: app.fullImageURL).frame(width: 120, height: 120).clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(app.name).font(.title.bold())
                                Text(app.developer ?? "Ashte Store").foregroundColor(.secondary)
                                HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                                    .frame(width: 90).padding(.top, 5)
                            }
                        }
                    }.padding(.top, 60).padding(.horizontal, 25)
                }
                
                // Detailed Info
                VStack(alignment: .leading, spacing: 20) {
                    Text("Details").font(.title2.bold())
                    
                    HStack {
                        InfoBox(title: "SIZE", value: app.size ?? "N/A", icon: "sdcard")
                        InfoBox(title: "VERSION", value: app.version ?? "1.0", icon: "clock")
                    }
                    
                    Text("What's New").font(.headline)
                    Text(app.hack?.joined(separator: "\n") ?? "Performance improvements and bug fixes.")
                        .foregroundColor(.secondary).lineSpacing(6)
                }
                .padding(25)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(35, corners: [.topLeft, .topRight])
                .offset(y: -30)
            }
        }
        .ignoresSafeArea().navigationBarHidden(true)
    }
}

struct InfoBox: View {
    let title: String; let value: String; let icon: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(.blue)
            Text(title).font(.caption2).foregroundColor(.secondary)
            Text(value).font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity).padding().background(Color(UIColor.systemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: style)) }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Download Logic (Optimized)
struct HomeDownloadButtonView: View {
    let app: HomeApp; @ObservedObject var downloadManager: DownloadManager; var onDownloadComplete: () -> Void 
    @StateObject private var downloader = HomeAppDownloader()
    
    var body: some View {
        Button(action: {
            if let url = URL(string: app.url) {
                downloader.start(url: url) { local in
                    _ = downloadManager.startDownload(from: local)
                    onDownloadComplete()
                }
            }
        }) {
            Group {
                if downloader.isDownloading {
                    ProgressView(value: downloader.progress).tint(.white).padding(.horizontal, 5)
                } else {
                    Text(downloader.isFinished ? "OPEN" : "GET")
                        .font(.system(size: 13, weight: .black))
                }
            }
            .frame(maxWidth: .infinity).frame(height: 30)
            .background(downloader.isFinished ? Color.gray.opacity(0.2) : Color.blue)
            .foregroundColor(downloader.isFinished ? .primary : .white)
            .clipShape(Capsule())
        }
    }
}

class HomeAppDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: CGFloat = 0
    @Published var isDownloading = false
    @Published var isFinished = false
    
    func start(url: URL, completion: @escaping (URL) -> Void) {
        self.isDownloading = true
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.downloadTask(with: url).resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        DispatchQueue.main.async { self.isDownloading = false; self.isFinished = true }
    }
}
