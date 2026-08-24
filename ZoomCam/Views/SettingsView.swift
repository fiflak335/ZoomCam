import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                // Camera Section
                Section {
                    Toggle(isOn: $settings.showGrid) {
                        Label("Grid Lines", systemImage: "grid")
                    }

                    Toggle(isOn: $settings.hapticFeedback) {
                        Label("Haptic Feedback", systemImage: "hand.tap")
                    }

                    Toggle(isOn: $settings.autoSave) {
                        Label("Auto Save Photos", systemImage: "arrow.down.circle")
                    }
                } header: {
                    Label("Camera", systemImage: "camera.fill")
                } footer: {
                    Text("Grid lines help with composition using the rule of thirds.")
                }

                // Photo Quality Section
                Section {
                    Picker("Photo Quality", selection: $settings.photoQuality) {
                        ForEach(PhotoQuality.allCases, id: \.self) { quality in
                            Text(quality.rawValue).tag(quality)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle(isOn: $settings.saveOriginal) {
                        Label("Keep Original Photo", systemImage: "photo.on.rectangle")
                    }
                } header: {
                    Label("Photo", systemImage: "photo.fill")
                }

                // AI Upscaling Section
                Section {
                    Picker("Upscale Factor", selection: $settings.upscaleFactor) {
                        ForEach(UpscaleFactor.allCases, id: \.self) { factor in
                            Text(factor.rawValue).tag(factor)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Higher upscale factors produce larger images but take longer to process.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Label("AI Upscaling", systemImage: "sparkles")
                }

                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2026.08")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/fiflak335/ZoomCam")!) {
                        HStack {
                            Label("GitHub Repository", systemImage: "chevron.left.forwardslash.chevron.right")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("About", systemImage: "info.circle")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
