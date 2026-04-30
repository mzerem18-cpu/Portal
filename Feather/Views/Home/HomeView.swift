import SwiftUI
import NimbleViews
import Foundation
import UIKit

// MARK: - 1. Data Model
// ئەم بەشە زانیاری ئەپەکان ڕێکدەخات
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

// MARK: - 2. Main Home View
struct HomeView: View {
    @StateObject var downloadManager = DownloadManager.shared
    @State private var apps: [HomeApp] = []
    @State private var showNotification = false
    @State private var downloadedApp: HomeApp? = nil
    
    var featuredApps: [HomeApp] {
        Array(apps.filter { $0.status == "new" || $0.status == "top" || $0.status == "update" }.prefix(5))
    }
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            NBNavigationView("Discover") {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        // Featured Slider
                        if !featuredApps.isEmpty {
                            TabView {
                                ForEach(featuredApps) { app in
                                    NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                        showDownloadNotification(for: app)
                                    }) {
                                        FeaturedHeroCard(app: app)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(height: 280)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            .padding(.top, 10)
                        }
                        
                        // App Sections
                        VStack(alignment: .leading, spacing: 30) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 15) {
                                    HStack {
                                        Text(category)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                        Spacer()
                                        Image(systemName: "chevron.right").foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 25)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 18) {
                                            ForEach(categoryApps) { app in
                                                NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                                    showDownloadNotification(for: app)
                                                }) {
                                                    AppCardView(app: app, downloadManager: downloadManager) {
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
                        
                        SocialFooterView().padding(.bottom, 50)
                    }
                }
                .refreshable { await loadApps() }
            }
            .onAppear { Task { await loadApps() } }
            
            // Modern Alert
            if showNotification, let app = downloadedApp {
                DownloadToast(app: app)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring()) { self.showNotification = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { self.showNotification = false }
        }
    }
    
    private func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ipa.json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([HomeApp].self, from: data)
            DispatchQueue.main.async { self.apps = decoded }
        } catch { print("Error loading data") }
    }
}

// MARK: - 3. UI Components (Cards)

struct FeaturedHeroCard: View {
    let app: HomeApp
    var body: some View {
        AsyncImage(url: app.fullBannerURL) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.gray.opacity(0.1)
        }
        .frame(width: UIScreen.main.bounds.width - 50, height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Text(app.name).font(.headline).foregroundColor(.white)
                    Spacer()
                    Text("New").font(.caption2.bold()).padding(5).background(.blue).foregroundColor(.white).cornerRadius(5)
                }
                .padding(20)
                .background(LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .padding(.horizontal, 25)
    }
}

struct AppCardView: View {
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
            .frame(width: 110, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
            
            Text(app.name).font(.system(size: 14, weight: .bold)).lineLimit(1)
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
        }
        .frame(width: 110)
    }
}

// MARK: - 4. Detail View
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
                        .frame(maxWidth: .infinity).frame(height: 300).clipped().blur(radius: 50).opacity(0.3)
                    
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
                
                // Info Grid
                VStack(alignment: .leading, spacing: 20) {
                    Text("Information").font(.title2.bold())
                    
                    VStack(spacing: 15) {
                        DetailRow(t: "Version", v: app.version ?? "1.0")
                        DetailRow(t: "Size", v: app.size ?? "Unknown")
                        DetailRow(t: "Bundle", v: app.bundle ?? "com.ashte.app")
                    }
                    .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(20)
                    
                    Text("Features").font(.headline)
                    Text(app.hack?.joined(separator: "\n") ?? "Standard premium features included.")
                        .foregroundColor(.secondary).lineSpacing(5)
                }
                .padding(25)
            }
        }
        .navigationBarHidden(true).ignoresSafeArea(edges: .top)
    }
}

struct DetailRow: View {
    let t: String; let v: String
    var body: some View {
        HStack { Text(t).foregroundColor(.secondary); Spacer(); Text(v).bold() }
    }
}

// MARK: - 5. Downloader & Button
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
            if downloader.isDownloading {
                ProgressView(value: downloader.progress).tint(.blue).frame(height: 4)
            } else {
                Text(downloader.isFinished ? "OPEN" : "GET")
                    .font(.system(size: 13, weight: .black))
                    .frame(maxWidth: .infinity).frame(height: 30)
                    .background(Color.blue.opacity(0.1)).foregroundColor(.blue).clipShape(Capsule())
            }
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
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ipa")
        try? FileManager.default.copyItem(at: location, to: dest)
        DispatchQueue.main.async { self.isDownloading = false; self.isFinished = true }
    }
}

// MARK: - 6. Misc Views
struct DownloadToast: View {
    let app: HomeApp
    var body: some View {
        HStack {
            Image(systemName: "arrow.down.circle.fill").foregroundColor(.blue)
            Text("\(app.name) Downloaded").font(.subheadline.bold())
        }
        .padding().background(.ultraThinMaterial).clipShape(Capsule()).padding(.top, 20)
    }
}

struct SocialFooterView: View {
    var body: some View {
        HStack(spacing: 20) {
            SocialIcon(i: "paperplane.fill", c: .blue, u: "https://t.me/ashtemobile")
            SocialIcon(i: "camera.fill", c: .pink, u: "https://instagram.com/ashtemobile")
        }
        .padding().frame(maxWidth: .infinity).background(Color.gray.opacity(0.05)).cornerRadius(25).padding(.horizontal, 25)
    }
}

struct SocialIcon: View {
    let i: String; let c: Color; let u: String
    var body: some View {
        Button(action: { UIApplication.shared.open(URL(string: u)!) }) {
            Image(systemName: i).foregroundColor(.white).padding(12).background(c).clipShape(Circle())
        }
    }
}
