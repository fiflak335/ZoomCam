import SwiftUI

struct PreviewView: View {
    let image: UIImage
    @ObservedObject var upscaler: AIUpscaler
    @ObservedObject var settings: SettingsManager
    let onRetake: () -> Void
    let onUpscaled: (UIImage, UpscaleInfo) -> Void

    @State private var isUpscaling = false
    @State private var showingSaveAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: onRetake) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Retake")
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.yellow)
                    }
                    .padding()

                    Spacer()

                    Text("Preview")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Spacer()
                        .frame(width: 80)
                }
                .background(.ultraThinMaterial)

                Spacer()

                // Image preview
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()

                Spacer()

                // Bottom controls
                VStack(spacing: 16) {
                    if isUpscaling {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                                .scaleEffect(1.2)

                            Text("Enhancing with AI...")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.vertical, 20)
                    } else {
                        // Action buttons
                        HStack(spacing: 12) {
                            // Save original
                            Button(action: saveOriginal) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save")
                                }
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                            }

                            // AI Upscale
                            Button(action: performUpscale) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                    Text("AI Upscale \(settings.upscaleFactor.rawValue)")
                                }
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .yellow.opacity(0.3), radius: 10, y: 5)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
                .background(.ultraThinMaterial)
            }
        }
        .alert("Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Photo saved to your library")
        }
    }

    private func performUpscale() {
        isUpscaling = true

        Task {
            if let result = await upscaler.upscaleImageWithDetails(image, scale: settings.upscaleFactor.value) {
                await MainActor.run {
                    isUpscaling = false
                    onUpscaled(result.upscaled, result.details)
                }
            } else {
                await MainActor.run {
                    isUpscaling = false
                }
            }
        }
    }

    private func saveOriginal() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showingSaveAlert = true
    }
}
