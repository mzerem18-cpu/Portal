//
//  SigningOptionsSharedView.swift
//  Feather
//
//  Created by samara on 15.04.2025.
//  Modernized Premium UI Integrated
//

import SwiftUI
import NimbleViews

// MARK: - View
struct SigningOptionsView: View {
    @Binding var options: Options
    var temporaryOptions: Options?
    
    // MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            // MARK: - Protection Section
            if (temporaryOptions == nil) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(.localized("Protection"))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.leading, 8)
                    
                    VStack(spacing: 0) {
                        _modernToggle(
                            title: .localized("PPQ Protection"),
                            icon: "shield.fill",
                            iconColor: .indigo,
                            isOn: $options.ppqProtection,
                            temporaryValue: temporaryOptions?.ppqProtection
                        )
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    
                    Text(.localized("Enabling any protection will append a random string to the bundleidentifiers of the apps you sign, this is to ensure your Apple ID does not get flagged by Apple. However, when using a signing service you can ignore this."))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                }
            }
            
            // MARK: - General Section
            VStack(alignment: .leading, spacing: 8) {
                Text(.localized("General"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.leading, 8)
                
                VStack(spacing: 0) {
                    _modernPicker(
                        title: .localized("Appearance"),
                        icon: "paintpalette.fill",
                        iconColor: .purple,
                        selection: $options.appAppearance,
                        values: Options.AppAppearance.allCases
                    )
                    
                    Divider().padding(.leading, 50)
                    
                    _modernPicker(
                        title: .localized("Minimum Requirement"),
                        icon: "ruler.fill",
                        iconColor: .blue,
                        selection: $options.minimumAppRequirement,
                        values: Options.MinimumAppRequirement.allCases
                    )
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                
                // Signing Type Card
                VStack(spacing: 0) {
                    _modernPicker(
                        title: .localized("Signing Type"),
                        icon: "signature",
                        iconColor: .teal,
                        selection: $options.signingOption,
                        values: Options.SigningOption.allCases
                    )
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                .padding(.top, 8) // بۆشایی لە نێوان دوو کارتەکە
            }
            
            // MARK: - App Features Section
            VStack(alignment: .leading, spacing: 8) {
                Text(.localized("App Features"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.leading, 8)
                
                VStack(spacing: 0) {
                    _modernToggle(title: .localized("File Sharing"), icon: "folder.badge.person.crop", iconColor: .blue, isOn: $options.fileSharing, temporaryValue: temporaryOptions?.fileSharing)
                    Divider().padding(.leading, 50)
                    
                    _modernToggle(title: .localized("iTunes File Sharing"), icon: "music.note.list", iconColor: .pink, isOn: $options.itunesFileSharing, temporaryValue: temporaryOptions?.itunesFileSharing)
                    Divider().padding(.leading, 50)
                    
                    _modernToggle(title: .localized("Pro Motion"), icon: "speedometer", iconColor: .orange, isOn: $options.proMotion, temporaryValue: temporaryOptions?.proMotion)
                    Divider().padding(.leading, 50)
                    
                    _modernToggle(title: .localized("Game Mode"), icon: "gamecontroller.fill", iconColor: .green, isOn: $options.gameMode, temporaryValue: temporaryOptions?.gameMode)
                    Divider().padding(.leading, 50)
                    
                    _modernToggle(title: .localized("iPad Fullscreen"), icon: "ipad.landscape", iconColor: .indigo, isOn: $options.ipadFullscreen, temporaryValue: temporaryOptions?.ipadFullscreen)
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
            
            // MARK: - Removal Section
            VStack(alignment: .leading, spacing: 8) {
                Text(.localized("Removal"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.leading, 8)
                
                VStack(spacing: 0) {
                    _modernToggle(title: .localized("Remove URL Scheme"), icon: "ellipsis.curlybraces", iconColor: .red, isOn: $options.removeURLScheme, temporaryValue: temporaryOptions?.removeURLScheme)
                    Divider().padding(.leading, 50)
                    
                    _modernToggle(title: .localized("Remove Provisioning"), icon: "doc.badge.gearshape.fill", iconColor: .purple, isOn: $options.removeProvisioning, temporaryValue: temporaryOptions?.removeProvisioning)
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                
                Text(.localized("Removing the provisioning file will exclude the mobileprovision file from being embedded inside of the application when signing, to help prevent any detection."))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }
            
            // MARK: - Force Localize
            VStack(alignment: .leading, spacing: 8) {
                VStack(spacing: 0) {
                    _modernToggle(title: .localized("Force Localize"), icon: "character.bubble.fill", iconColor: .teal, isOn: $options.changeLanguageFilesForCustomDisplayName, temporaryValue: temporaryOptions?.changeLanguageFilesForCustomDisplayName)
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                
                Text(.localized("By default, localized titles for the app won't be changed, however this option overrides it."))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }
            
            // MARK: - Post Signing
            VStack(alignment: .leading, spacing: 8) {
                Text(.localized("Post Signing"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.leading, 8)
                
                VStack(spacing: 0) {
                    _modernToggle(title: .localized("Install After Signing"), icon: "arrow.down.circle.fill", iconColor: .cyan, isOn: $options.post_installAppAfterSigned, temporaryValue: temporaryOptions?.post_installAppAfterSigned)
                    Divider().padding(.leading, 50)
                    
                    _modernToggle(title: .localized("Delete After Signing"), icon: "trash.fill", iconColor: .red, isOn: $options.post_deleteAppAfterSigned, temporaryValue: temporaryOptions?.post_deleteAppAfterSigned)
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                
                Text(.localized("This will delete your imported application after signing, to save on using unneeded space."))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }
            
            // MARK: - Experiments
            VStack(alignment: .leading, spacing: 8) {
                Text(.localized("Experiments"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.leading, 8)
                
                VStack(spacing: 0) {
                    _modernToggle(title: .localized("Replace Substrate with ElleKit"), icon: "pencil.and.outline", iconColor: .orange, isOn: $options.experiment_replaceSubstrateWithEllekit, temporaryValue: temporaryOptions?.experiment_replaceSubstrateWithEllekit)
                    Divider().padding(.leading, 50)
                    
                    _modernToggle(title: .localized("Enable Liquid Glass"), icon: "26.circle.fill", iconColor: .blue, isOn: $options.experiment_supportLiquidGlass, temporaryValue: temporaryOptions?.experiment_supportLiquidGlass)
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                
                Text(.localized("This option force converts apps to try to use the new liquid glass redesign iOS 26 introduced, this may not work for all applications due to differing frameworks."))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }
            
        } // کۆتایی VStack سەرەکی
        // تێبینی: لێرەدا پێویست بە ScrollView ناکات چونکە ئەم پەڕەیە دەچێتە ناو ScrollViewـی سەرەکی فایلی ConfigurationView
    }
}

// MARK: - Helper UI Builders
extension SigningOptionsView {
    
    // دیزاینی مۆدێرن بۆ Picker (وەک Appearance و Signing Type)
    @ViewBuilder
    private func _modernPicker<SelectionValue: Hashable, T: Hashable & LocalizedDescribable>(
        title: String,
        icon: String,
        iconColor: Color,
        selection: Binding<SelectionValue>,
        values: [T]
    ) -> some View {
        HStack(spacing: 15) {
            ZStack {
                iconColor.opacity(0.15)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(width: 32, height: 32)
            .cornerRadius(8)
            
            Picker(selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(value.localizedDescription)
                }
            } label: {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
            }
            .pickerStyle(.menu)
            .tint(.secondary) // ڕەنگی هەڵبژاردەکە ستاندارد دەکات
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8) // Picker خۆی کەمێک بۆشایی هەیە، بۆیە 8 بەسە
    }
    
    // دیزاینی مۆدێرن بۆ Toggle (دوگمەی داگیرساندن/کوژاندنەوە)
    @ViewBuilder
    private func _modernToggle(
        title: String,
        icon: String,
        iconColor: Color,
        isOn: Binding<Bool>,
        temporaryValue: Bool? = nil
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 15) {
                ZStack {
                    iconColor.opacity(0.15)
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(width: 32, height: 32)
                .cornerRadius(8)
                
                if let tempValue = temporaryValue, tempValue != isOn.wrappedValue {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                } else {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .tint(Color(hex: "#848ef9")) // ڕەنگی مۆدێرنی AshteMobile بۆ داگیرساندن
    }
}
