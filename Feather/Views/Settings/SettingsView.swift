import SwiftUI
import NimbleViews
import UIKit

// MARK: - View
struct SettingsView: View {
    @AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
    @State private var _currentIcon: String? = UIApplication.shared.alternateIconName
    
    // MARK: Fetch
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var _certificates: FetchedResults<CertificatePair>
    
    private var selectedCertificate: CertificatePair? {
        guard
            _storedSelectedCert >= 0,
            _storedSelectedCert < _certificates.count
        else {
            return nil
        }
        return _certificates[_storedSelectedCert]
    }

    // MARK: Body
    var body: some View {
        NBNavigationView(.localized("Settings")) {
            Form {
                // MARK: - Header (Logo & Brand)
                Section {
                    VStack(spacing: 12) {
                        AsyncImage(url: URL(string: "https://ashtemobile.tututweak.com/a.png")) { image in
                            image.resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 90, height: 90)
                                .overlay(ProgressView())
                        }
                        
                        Text("AshteMobile")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        
                        HStack(spacing: 15) {
                            // Telegram
                            Link(destination: URL(string: "https://t.me/ashtemobile")!) {
                                SocialIcon(image: "paperplane.fill", color: .blue)
                            }
                            
                            // Instagram
                            Link(destination: URL(string: "https://www.instagram.com/ashtemobile")!) {
                                SocialIcon(image: "camera.fill", color: .pink)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                }
                .listRowBackground(Color.clear)

                // MARK: - General
                NBSection(.localized("General")) {
                    NavigationLink(destination: AboutView()) {
                        Label(.localized("About"), systemImage: "info.circle.fill")
                            .foregroundColor(.blue)
                    }
                    NavigationLink(destination: AppearanceView()) {
                        Label(.localized("Appearance"), systemImage: "paintbrush.fill")
                            .foregroundColor(.purple)
                    }
                    NavigationLink(destination: AppIconView(currentIcon: $_currentIcon)) {
                        Label(.localized("App Icon"), systemImage: "app.badge.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                // MARK: - Certificates
                NBSection(.localized("Certificates")) {
                    if let cert = selectedCertificate {
                        CertificatesCellView(cert: cert)
                    } else {
                        Text(.localized("No Certificate Selected"))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    NavigationLink(destination: CertificatesView()) {
                        Label(.localized("Manage Certificates"), systemImage: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                }
                
                // MARK: - App Features
                NBSection(.localized("Features")) {
                    NavigationLink(destination: ConfigurationView()) {
                        Label(.localized("Signing Options"), systemImage: "signature")
                            .foregroundColor(.cyan)
                    }
                    NavigationLink(destination: InstallationView()) {
                        Label(.localized("Installation"), systemImage: "arrow.down.circle.fill")
                            .foregroundColor(.indigo)
                    }
                    NavigationLink(destination: ArchiveView()) {
                        Label(.localized("Archive & Compression"), systemImage: "archivebox.fill")
                            .foregroundColor(.brown)
                    }
                }
                
                // MARK: - Files & Storage
                NBSection(.localized("Storage")) {
                    Button {
                        UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!)
                    } label: {
                        Label(.localized("Documents"), systemImage: "folder.fill")
                    }
                    
                    Button {
                        UIApplication.open(FileManager.default.certificates.toSharedDocumentsURL()!)
                    } label: {
                        Label(.localized("Certificates Folder"), systemImage: "lock.folder.fill")
                    }
                }
                
                // MARK: - Danger Zone
                Section {
                    NavigationLink(destination: ResetView()) {
                        Label(.localized("Reset All Data"), systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

// MARK: - Helper View for Social Buttons
struct SocialIcon: View {
    let image: String
    let color: Color
    
    var body: some View {
        Image(systemName: image)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 38, height: 38)
            .background(color)
            .clipShape(Circle())
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
    }
}
