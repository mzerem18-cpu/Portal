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
    
    var featuredApps: [HomeApp] {
        Array(apps.filter { $0.status == "new" || $0.status == "top" || $0.status == "update" }.prefix(3))
    }
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // پاشبنەمایەکی مۆدێرن و درەوشاوە
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            GeometryReader { proxy in
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: proxy.size.width * 1.5, height: proxy.size.width * 1.5)
                    .blur(radius: 60)
                    .offset(x: -proxy.size.width * 0.2, y: -proxy.size.width * 0.5)
            }
            .ignoresSafeArea()
            
            NBNavigationView("Discover") { // گۆڕینی ناو بۆ دیزاینێکی مۆدێرنتر
                ScrollView {
                    VStack(spacing: 40) {
                        
                        // Featured Section
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
                            .frame(height: 280)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        }
                        
                        // Categories Section
                        VStack(alignment: .leading, spacing: 35) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 20) {
                                    HStack(alignment: .lastTextBaseline) {
                                        Text(category)
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                        Spacer()
                                        Text("See All")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 20) {
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
                                        .padding(.horizontal, 24)
                                        .padding(.bottom, 20)
                                        .padding(.top, 5)
                                    }
                                }
                            }
                        }
                        
                        SocialMediaFooter()
                            .padding(.top, 10)
                            .padding(.bottom, 50)
                    }
                    .padding(.top, 20)
                }
                .refreshable {
                    await loadApps()
                }
            }
            .onAppear {
                Task { await loadApps() }
            }
            
            // Premium Notification Banner
            if showNotification, let app = downloadedApp {
                notificationBanner(for: app)
                    .padding(.top, safeAreaTop() + 10)
                    .zIndex(100)
            }
        }
        .preferredColorScheme(.dark) // یارمەتیدەرە بۆ ئەوەی دیزاینەکە مۆدێرنتر دەربکەوێت بە شێوازی تاریک
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            self.showNotification = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.showNotification = false
            }
        }
    }
    
    @ViewBuilder
    private func notificationBanner(for app: HomeApp) -> some View {
        HStack(alignment: .center, spacing: 16) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Ready to Install")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("\(app.name) has been added.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.blue)
                .font(.system(size: 26))
                .symbolRenderingMode(.multicolor)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 25, x: 0, y: 15)
        .padding(.horizontal, 20)
        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity.combined(with: .scale(scale: 0.9))))
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
    
    private func safeAreaTop() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        return window?.safeAreaInsets.top ?? 44
    }
}

// MARK: - App Detail View
struct HomeAppDetailView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // Cinematic Hero Header
                    GeometryReader { proxy in
                        let minY = proxy.frame(in: .global).minY
                        let isScrolledDown = minY > 0
                        let height = isScrolledDown ? 320 + minY : 320
                        let offset = isScrolledDown ? -minY : 0

                        ZStack(alignment: .top) {
                            AsyncImage(url: app.fullImageURL) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                            .frame(width: proxy.size.width, height: height)
                            .clipped()
                            .overlay(
                                LinearGradient(colors: [.clear, Color(UIColor.systemBackground)], startPoint: .center, endPoint: .bottom)
                            )
                            .offset(y: offset)
                            
                            // Navigation Buttons
                            HStack {
                                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial)
                                        .environment(\.colorScheme, .dark)
                                        .clipShape(Circle())
                                }
                                Spacer()
                                
                                Button(action: {
                                    let shareText = "Download \(app.name) from AshteMobile Store!\nhttps://t.me/ashtemmobile"
                                    let av = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                                    UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial)
                                        .environment(\.colorScheme, .dark)
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, safeAreaTop() + 10)
                        }
                    }
                    .frame(height: 320)
                    
                    // App Info Header (Floating Effect)
                    HStack(alignment: .center, spacing: 20) {
                        AsyncImage(url: app.fullImageURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(app.name)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(app.developer ?? "AshteMobile")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                                .frame(width: 100)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .offset(y: -60)
                    .padding(.bottom, -30)
                    
                    // Glassmorphic Stats
                    HStack(spacing: 16) {
                        StatCard(icon: "bolt.fill", title: "Version", value: app.version ?? "1.0")
                        StatCard(icon: "externaldrive.fill", title: "Size", value: app.size ?? "Unknown")
                        StatCard(icon: "chart.bar.fill", title: "Category", value: app.category ?? "App")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 35)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About this app")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            if let hacks = app.hack, !hacks.isEmpty {
                                ForEach(hacks, id: \.self) { hack in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 16))
                                            .padding(.top, 2)
                                        Text(hack)
                                            .font(.system(size: 15, weight: .regular, design: .rounded))
                                            .foregroundColor(.primary.opacity(0.8))
                                            .lineSpacing(4)
                                    }
                                }
                            } else {
                                Text("Download \(app.name) now and enjoy smooth performance and regular updates directly from the AshteMobile Store.")
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundColor(.primary.opacity(0.8))
                                    .lineSpacing(6)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 35)
                    
                    // Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Information")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        
                        VStack(spacing: 0) {
                            AppInfoRow(title: "Source", value: "AshteMobile Repo", isLast: false)
                            AppInfoRow(title: "Developer", value: app.developer ?? "Unknown", isLast: false)
                            AppInfoRow(title: "Size", value: app.size ?? "Unknown", isLast: false)
                            AppInfoRow(title: "Version", value: app.version ?? "1.0", isLast: false)
                            AppInfoRow(title: "Identifier", value: app.bundle ?? "com.ashte.\(app.name.replacingOccurrences(of: " ", with: "").lowercased())", isLast: true)
                        }
                        .background(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60)
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(edges: .top)
        }
    }
    
    private func safeAreaTop() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        return window?.safeAreaInsets.top ?? 44
    }
}

// MARK: - Reusable Components
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct AppInfoRow: View {
    let title: String
    let value: String
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            if !isLast {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 20)
            }
        }
    }
}

// MARK: - Featured App View (Banner)
struct FeaturedAppView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: app.fullBannerURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(height: 280)
            
            // Rich Gradient Overlay
            LinearGradient(colors: [.clear, .black.opacity(0.4), .black.opacity(0.9)], startPoint: .top, endPoint: .bottom)
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    if let status = app.status {
                        Text(status.uppercased())
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                    
                    Text(app.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(app.category ?? "Featured Collection")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                
                HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                    .frame(width: 85)
                    .environment(\.colorScheme, .dark)
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Category App Card View
struct HomeAppCardView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(width: 85, height: 85)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 4) {
                Text(app.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text(app.category ?? "App")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 5)
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
        }
        .padding(16)
        .frame(width: 145, height: 220)
        .background(.ultraThinMaterial)
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Social Media Footer
struct SocialMediaFooter: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Connect With Us")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            HStack(spacing: 28) {
                SocialButton(icon: "paperplane.fill", color: .blue, url: "https://t.me/ashtemobile")
                SocialButton(icon: "camera.fill", color: .purple, url: "https://www.instagram.com/ashtemobile")
                SocialButton(icon: "play.tv.fill", color: .primary, url: "https://www.tiktok.com/@ashtemobile")
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, 24)
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
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(colors: [color.opacity(0.8), color], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
                .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Downloader & Button
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

struct HomeDownloadButtonView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    @StateObject private var downloader = HomeAppDownloader()
    
    var body: some View {
        ZStack {
            if downloader.isFinished {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
            } else if downloader.isDownloading {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3.5)
                        .frame(width: 30, height: 30)
                    
                    if downloader.progress > 0 {
                        Circle()
                            .trim(from: 0, to: downloader.progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 30, height: 30)
                            .animation(.linear(duration: 0.2), value: downloader.progress)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    }
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .onTapGesture {
                            withAnimation { downloader.stop() }
                        }
                }
                .frame(height: 34)
            } else {
                Button(action: {
                    if let downloadURL = URL(string: app.url) {
                        let generator = UIImpactFeedbackGenerator(style: .rigid)
                        generator.impactOccurred()
                        
                        withAnimation {
                            downloader.start(url: downloadURL) { localURL in
                                _ = downloadManager.startDownload(from: localURL)
                                DispatchQueue.main.async {
                                    onDownloadComplete()
                                }
                            }
                        }
                    }
                }) {
                    Text("GET")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle()) 
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: downloader.isDownloading)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: downloader.isFinished)
    }
}
