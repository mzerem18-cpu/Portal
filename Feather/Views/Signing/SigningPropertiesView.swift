//
//  SigningAppPropertiesView.swift
//  Feather
//
//  Created by samara on 17.04.2025.
//  Modernized Premium UI
//

import SwiftUI
import NimbleViews

// MARK: - View
struct SigningPropertiesView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var text: String = ""
    
    var saveButtonDisabled: Bool {
        text == initialValue
    }
    
    var title: String
    var initialValue: String 
    @Binding var bindingValue: String?
    
    // MARK: Body
    var body: some View {
        ZStack {
            // باکگراوندی مۆدێرن
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // سەردێڕی بەشەکە
                        Text(title.uppercased())
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                        
                        // کارتی نووسینەکە
                        VStack {
                            HStack(spacing: 12) {
                                TextField(initialValue, text: $text)
                                    .textInputAutocapitalization(.none)
                                    .font(.system(size: 16, weight: .regular))
                                    .padding(.vertical, 14)
                                
                                // دوگمەیەک بۆ سڕینەوە یان گەڕاندنەوە بۆ باری پێشوو بە شێوەیەکی پڕۆفیشناڵ
                                if text != initialValue {
                                    Button(action: {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        text = initialValue
                                    }) {
                                        Image(systemName: "arrow.uturn.backward.circle.fill")
                                            .foregroundColor(.gray.opacity(0.5))
                                            .font(.system(size: 18))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        
                        // ڕوونکردنەوە لە خوارەوەی کارتەکە
                        Text("Enter a new \(title.lowercased()) to apply during the signing process.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NBToolbarButton(
                .localized("Save"),
                style: .text,
                placement: .topBarTrailing,
                isDisabled: saveButtonDisabled
            ) {
                if !saveButtonDisabled {
                    bindingValue = text
                    dismiss()
                }
            }
        }
        .onAppear {
            text = initialValue
        }
    }
}
