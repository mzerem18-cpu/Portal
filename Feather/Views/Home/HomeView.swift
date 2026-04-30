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
}

// MARK: - Main Home View (Ultra Modern 2026 Style)
struct HomeView: View {
    @StateObject var downloadManager = DownloadManager.shared
    @State private var apps: [HomeApp] = []
    @State private var showNotification = false
    @State private var downloadedApp: HomeApp? = nil
    
    var featuredApps: [HomeApp] {
        Array(apps.filter { $0.status == "new" || $0.status == "top" }.prefix(6))
    }
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Applications" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            NBNavigationView("Store") {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 40) {
                        
                        // MARK: - Header Section
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ASHTE MOBILE")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.blue)
                                .tracking(2)
                            Text("New & Notable")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        // MARK: - Featured Horizontal Grid
                        if !featuredApps.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(featuredApps) { app in
                                        NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                            showDownloadNotification(for: app)
                                        }) {
                                            FeaturedNeoCard(app: app)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // MARK: - Category Sections
                        ForEach(groupedApps, id: \.0) { category, categoryApps in
                            VStack(alignment: .leading, spacing: 20) {
                                Text(category)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 24)
                                
                                ForEach(categoryApps) { app in
                                    NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                        showDownloadNotification(for: app)
                                    }) {
                                        ModernListRow(app: app, downloadManager: downloadManager) {
                                            showDownloadNotification(for: app)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    Divider().padding(.leading, 100).padding(.trailing, 24).opacity(0.5)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 100)
                    }
                }
                .refreshable { await loadApps() }
            }
            .onAppear { Task { await loadApps() } }
            
            if showNotification, let app = downloadedApp {
                MinimalToast(app: app)
                    .padding(.top, 10)
                    .transition(.asymmetric(insertion: .move(edge: .top), removal: .opacity))
                    .zIndex(100)
            }
        }
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring()) { self.showNotification = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { self.showNotification = false }
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

// MARK: - UI Components

struct FeaturedNeoCard: View {
    let app: HomeApp
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(width: 240, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.category ?? "App")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.blue)
                Text(app.name)
                    .font(.system(size: 18, weight: .bold))
                Text(app.developer ?? "AshteMobile")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 240)
    }
}

struct ModernListRow: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 17, weight: .semibold))
                Text(app.developer ?? "AshteMobile")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                .frame(width: 74)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 4)
    }
}

struct MinimalToast: View {
    let app: HomeApp
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.blue)
            Text("\(app.name) added to library")
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Detail View
struct HomeAppDetailView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left").font(.title3).foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(24)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    HStack(alignment: .top, spacing: 20) {
                        AsyncImage(url: app.fullImageURL)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .shadow(color: Color.black.opacity(0.1), radius: 20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(app.name).font(.system(size: 24, weight: .bold))
                            Text(app.category ?? "Utility").foregroundColor(.secondary)
                            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                                .frame(width: 100).padding(.top, 5)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Information").font(.headline)
                        InfoRow(label: "Developer", value: app.developer ?? "Ashte")
                        InfoRow(label: "Size", value: app.size ?? "Unknown")
                        InfoRow(label: "Version", value: app.version ?? "1.0")
                    }
                    .padding(24)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct InfoRow: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }
}

// MARK: - Download Button
struct HomeDownloadButtonView: View {
    let app: HomeApp; @ObservedObject var downloadManager: DownloadManager; var onDownloadComplete: () -> Void
    @StateObject private var downloader = HomeAppDownloader()
    
    var body: some View {
        ZStack {
            if downloader.isDownloading {
                ZStack {
                    Circle().stroke(Color.blue.opacity(0.1), lineWidth: 3)
                    Circle().trim(from: 0, to: downloader.progress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 28, height: 28)
            } else {
                Button(action: {
                    if let url = URL(string: app.url) {
                        downloader.start(url: url) { local in
                            _ = downloadManager.startDownload(from: local)
                            onDownloadComplete()
                        }
                    }
                }) {
                    Text(downloader.isFinished ? "OPEN" : "GET")
                        .font(.system(size: 13, weight: .bold))
                        .padding(.vertical, 6).frame(maxWidth: .infinity)
                        .background(downloader.isFinished ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Downloader Logic
class HomeAppDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: CGFloat = 0
    @Published var isDownloading = false
    @Published var isFinished = false
    private var downloadTask: URLSessionDownloadTask?
    
    func start(url: URL, completion: @escaping (URL) -> Void) {
        self.isDownloading = true
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        downloadTask = session.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ipa")
        try? FileManager.default.copyItem(at: location, to: dest)
        DispatchQueue.main.async {
            self.isDownloading = false; self.isFinished = true
        }
    }
}
