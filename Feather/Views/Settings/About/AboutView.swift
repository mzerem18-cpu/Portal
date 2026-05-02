//
//  AboutView.swift
//  Feather
//
//  Modified for AshteMobile
//  Modernized Premium UI
//

import SwiftUI
import NimbleViews

// MARK: - View
struct AboutView: View {
    
    // MARK: Body
    var body: some View {
        ZStack {
            // باکگراوندی مۆدێرن بۆ پەڕەکە
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 35) {
                    
                    // MARK: - Header (Logo & Title)
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: "https://ashtemobile.tututweak.com/a.png")) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        } placeholder: {
                            ProgressView()
                                .frame(width: 100, height: 100)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }
                        
                        VStack(spacing: 6) {
                            Text("AshteMobile")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#848ef9")) // ڕەنگی مۆدێرن
                            
                            HStack(spacing: 4) {
                                Text("Version")
                                Text(Bundle.main.version) // بەکارهێنانی کۆدەکەی خۆت
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 40)
                    
                    // MARK: - Social Media Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Social Media")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.leading, 8)
                        
                        VStack(spacing: 0) {
                            _socialRow(name: "Telegram", url: "https://t.me/ashtemobile", icon: "paperplane.fill", color: .blue)
                            Divider().padding(.leading, 55)
                            
                            _socialRow(name: "Instagram", url: "https://www.instagram.com/ashtemobile", icon: "camera.fill", color: .pink)
                            Divider().padding(.leading, 55)
                            
                            _socialRow(name: "TikTok", url: "https://www.tiktok.com/@ashtemobile", icon: "play.tv.fill", color: .primary)
                            Divider().padding(.leading, 55)
                            
                            _socialRow(name: "Snapchat", url: "https://www.snapchat.com/add/ashtemzere", icon: "camera.filters", color: .yellow)
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    // MARK: - Footer
                    Text("BY AshteMobile❤️")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 30)
                        .padding(.top, 10)
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Extension: view
extension AboutView {
    @ViewBuilder
    private func _socialRow(name: String, url: String, icon: String, color: Color) -> some View {
        Button {
            if let parsedUrl = URL(string: url) {
                UIApplication.shared.open(parsedUrl)
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .regular))
                    .frame(width: 25, alignment: .center)
                
                Text(name)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// بۆ خوێندنەوەی ڕەنگی (Hex)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
