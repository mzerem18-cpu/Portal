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
            // Background Color
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            NBNavigationView("Ashte Store") {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        // MARK: - Welcome Header
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Welcome Back")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("Explore Everything")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 25)
                        .padding(.top, 10)

                        // MARK: - Floating Featured Slider
                        if !featuredApps.isEmpty {
                            TabView {
                                ForEach(featuredApps) { app in
                                    NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                        showDownloadNotification(for: app)
                                    }) {
                                        ModernHeroCard(app: app)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(height: 260)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        }
                        
                        // MARK: - Sections
                        VStack(alignment: .leading, spacing: 35) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 18) {
                                    HStack {
                                        Text(category)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                        Spacer()
                                        Image(systemName: "chevron.right.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                    }
                                    .padding(.horizontal, 25)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 20) {
                                            ForEach(categoryApps) { app in
                                                NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                                    showDownloadNotification(for: app)
                                                }) {
                                                    FuturisticAppCard(app: app, downloadManager: downloadManager) {
                                                        showDownloadNotification(for: app)
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 25)
                                    }
                                }
                            }
                        }
                        
                        SocialFooterView()
                            .padding(.bottom, 50)
                    }
                }
                .refreshable { await loadApps() }
            }
            .searchable(text: $searchText, prompt: "Search for apps...")
            .onAppear { Task { await loadApps() } }
            
            // Notification
            if showNotification, let app = downloadedApp {
                FloatingNotification(app: app)
                    .padding(.top, 20)
                    .zIndex(100)
            }
        }
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { self.showNotification = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
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

// MARK: - Modern UI Components

struct ModernHeroCard: View {
    let app: HomeApp
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: app.fullBannerURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.black.opacity(0.1)
            }
            .frame(width: UIScreen.main.bounds.width - 50, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
            
            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
            
            VStack(alignment: .leading, spacing: 5) {
                Text(app.status?.uppercased() ?? "NEW")
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.blue).foregroundColor(.white).clipShape(Capsule())
                
                Text(app.name)
                    .font(.title.bold())
                    .foregroundColor(.white)
            }
            .padding(25)
        }
        .shadow(color: Color.blue.opacity(0.2), radius: 15, x: 0, y: 10)
    }
}

struct FuturisticAppCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        VStack(spacing: 15) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(width: 90, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 4) {
                Text(app.name)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                
                HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
            }
        }
        .padding(15)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .frame(width: 130)
    }
}

struct FloatingNotification: View {
    let app: HomeApp
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title).foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text("App Ready").font(.headline)
                Text("\(app.name) is downloaded.").font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.horizontal, 25)
        .shadow(radius: 10)
    }
}

struct SocialFooterView: View {
    var body: some View {
        HStack(spacing: 20) {
            SocialIcon(img: "paperplane.fill", color: .blue, url: "https://t.me/ashtemobile")
            SocialIcon(img: "camera.fill", color: .pink, url: "https://instagram.com/ashtemobile")
        }
        .padding(25)
        .background(RoundedRectangle(cornerRadius: 30).fill(Color.blue.opacity(0.05)))
        .padding(.horizontal, 25)
    }
}

struct SocialIcon: View {
    let img: String; let color: Color; let url: String
    var body: some View {
        Button(action: { UIApplication.shared.open(URL(string: url)!) }) {
            Image(systemName: img)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 55, height: 55)
                .background(color.gradient)
                .clipShape(Circle())
        }
    }
}

// MARK: - Detail & Downloader Logic (Same as before but with UI tweaks)
struct HomeAppDetailView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: app.fullBannerURL ?? app.fullImageURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    }
                    .frame(height: 350).clipped()
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark").padding(10).background(.ultraThinMaterial).clipShape(Circle())
                    }.padding(.top, 50).padding(.leading, 20)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        AsyncImage(url: app.fullImageURL).frame(width: 100, height: 100).clipShape(RoundedRectangle(cornerRadius: 25))
                        VStack(alignment: .leading) {
                            Text(app.name).font(.title.bold())
                            Text(app.category ?? "App").foregroundColor(.secondary)
                            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete).frame(width: 100)
                        }
                    }
                    
                    Text("Details").font(.title2.bold())
                    Text(app.hack?.joined(separator: "\n") ?? "No hack info available").foregroundColor(.secondary)
                    
                    // Info Table
                    VStack(spacing: 15) {
                        InfoLine(t: "Developer", v: app.developer ?? "Unknown")
                        InfoLine(t: "Size", v: app.size ?? "N/A")
                        InfoLine(t: "Bundle", v: app.bundle ?? "N/A")
                    }
                    .padding().background(Color.gray.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(25)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(40, corners: [.topLeft, .topRight])
                .offset(y: -50)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

struct InfoLine: View {
    let t: String; let v: String
    var body: some View {
        HStack { Text(t).foregroundColor(.secondary); Spacer(); Text(v).bold() }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Logic (Downloader)
class HomeAppDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: CGFloat = 0
    @Published var isDownloading = false
    @Published var isFinished = false
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?
    private var downloadURL: URL?
    private var onFinished: ((URL) -> Void)?
    
    func start(url: URL, onFinished: @escaping (URL) -> Void) {
        self.downloadURL = url; self.onFinished = onFinished; self.isDownloading = true
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        downloadTask = session?.downloadTask(with: url); downloadTask?.resume()
    }
    
    func stop() { downloadTask?.cancel(); isDownloading = false }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 { DispatchQueue.main.async { self.progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite) } }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ipa")
        try? FileManager.default.copyItem(at: location, to: dest)
        DispatchQueue.main.async { self.isDownloading = false; self.isFinished = true; self.onFinished?(dest) }
    }
}

struct HomeDownloadButtonView: View {
    let app: HomeApp; @ObservedObject var downloadManager: DownloadManager; var onDownloadComplete: () -> Void 
    @StateObject private var downloader = HomeAppDownloader()
    
    var body: some View {
        Group {
            if downloader.isDownloading {
                ProgressView(value: downloader.progress).tint(.blue)
            } else {
                Button(action: {
                    if let url = URL(string: app.url) {
                        downloader.start(url: url) { localURL in
                            _ = downloadManager.startDownload(from: localURL)
                            onDownloadComplete()
                        }
                    }
                }) {
                    Text(downloader.isFinished ? "DONE" : "GET")
                        .font(.caption.bold())
                        .padding(.vertical, 6).frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1)).foregroundColor(.blue).clipShape(Capsule())
                }
            }
        }.frame(height: 30)
    }
}

private func safeAreaTop() -> CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44
}
