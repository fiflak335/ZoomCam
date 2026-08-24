import SwiftUI

struct PreviewView: View {
    let image: UIImage
    @ObservedObject var upscaler: AIUpscaler
    let onRetake: () -> Void
    let onUpscaled: (UIImage, UpscaleInfo) -> Void

    @State private var isUpscaling = false
    @State private var upscaleProgress: Float = 0
    @State private var showingSaveAlert = false
    @State private var saveError: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button("Retake") {
                        onRetake()
                    }
                    .foregroundColor(.yellow)
                    .padding()

                    Spacer()

                    Text("Preview")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Spacer()
                        .frame(width: 60)
                }

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
                        VStack(spacing: 8) {
                            ProgressView(value: upscaleProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                                .frame(width: 200)

                            Text("Upscaling with AI...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        // Action buttons
                        HStack(spacing: 20) {
                            // Save original
                            Button(action: saveOriginal) {
                                VStack {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.title2)
                                    Text("Save Original")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                            }

                            // AI Upscale
                            Button(action: performUpscale) {
                                VStack {
                                    Image(systemName: "sparkles")
                                        .font(.title2)
                                    Text("AI Upscale 4x")
                                        .font(.caption)
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 20)
                .background(Color.black.opacity(0.8))
            }
        }
        .alert("Image Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The image has been saved to your photo library.")
        }
        .alert("Save Error", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            if let error = saveError {
                Text(error)
            }
        }
    }

    private func performUpscale() {
        isUpscaling = true

        Task {
            if let result = await upscaler.upscaleImageWithDetails(image) {
                await MainActor.run {
                    isUpscaling = false
                    onUpscaled(result.upscaled, result.details)
                }
            } else {
                await MainActor.run {
                    isUpscaling = false
                    saveError = "Failed to upscale image"
                }
            }
        }
    }

    private func saveOriginal() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showingSaveAlert = true
    }
}
