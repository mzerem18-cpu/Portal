import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

// MARK: - Modern Settings View
struct SettingsView: View {
    @AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
    @State private var _currentIcon: String? = UIApplication.shared.alternateIconName
    
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var _certificates: FetchedResults<CertificatePair>
    
    private var selectedCertificate: CertificatePair? {
        guard _storedSelectedCert >= 0, _storedSelectedCert < _certificates.count else { return nil }
        return _certificates[_storedSelectedCert]
    }

    var body: some View {
        NBNavigationView(.localized("Settings")) {
            List {
                // MARK: - Modern Profile Header Card
                Section {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 110, height: 110)
                            
                            AsyncImage(url: URL(string: "https://ashtemobile.tututweak.com/a.png")) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            } placeholder: {
                                ProgressView().frame(width: 90, height: 90)
                            }
                        }
                        .padding(.top, 10)
                        
                        VStack(spacing: 6) {
                            Text("AshteMobile")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                            
                            Text("Premium Signing Experience")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12).padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1)).clipShape(Capsule())
                        }
                        
                        HStack(spacing: 15) {
                            _socialLink(icon: "paperplane.fill", title: "Telegram", color: .blue, url: "https://t.me/ashtemobile")
                            _socialLink(icon: "camera.fill", title: "Instagram", color: .pink, url: "https://www.instagram.com/ashtemobile")
                        }
                        .padding(.horizontal).padding(.bottom, 10)
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)

                // MARK: - Preferences
                Section("Preferences") {
                    NavigationLink(destination: AppearanceView()) {
                        _modernLabel("Appearance", icon: "paintbrush.fill", color: .purple)
                    }
                    NavigationLink(destination: AppIconView(currentIcon: $_currentIcon)) {
                        _modernLabel("App Icon", icon: "app.badge.fill", color: .indigo)
                    }
                }
                
                // MARK: - Security
                Section("Security") {
                    if let cert = selectedCertificate {
                        NavigationLink(destination: CertificatesView()) {
                            VStack(alignment: .leading, spacing: 8) {
                                _modernLabel("Active Certificate", icon: "checkmark.seal.fill", color: .green)
                                CertificatesCellView(cert: cert).scaleEffect(0.9).padding(.leading, -15)
                            }
                        }
                    } else {
                        NavigationLink(destination: CertificatesView()) {
                            _modernLabel("Manage Certificates", icon: "shield.slash.fill", color: .orange)
                        }
                    }
                }
                
                // MARK: - Tools
                Section("Tools") {
                    NavigationLink(destination: ConfigurationView()) {
                        _modernLabel("Signing Options", icon: "signature", color: .orange)
                    }
                    NavigationLink(destination: InstallationView()) {
                        _modernLabel("Installation", icon: "arrow.down.circle.fill", color: .blue)
                    }
                }

                // MARK: - System
                Section("System") {
                    NavigationLink(destination: ResetView()) {
                        _modernLabel("Reset All Data", icon: "trash.fill", color: .red)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    @ViewBuilder
    private func _modernLabel(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.gradient)
                    .frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
            }
            Text(.localized(title)).font(.system(size: 16, weight: .medium))
        }
    }
    
    @ViewBuilder
    private func _socialLink(icon: String, title: String, color: Color, url: String) -> some View {
        Button(action: { UIApplication.shared.open(URL(string: url)!) }) {
            HStack { Image(systemName: icon); Text(title) }
                .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(color.gradient).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
