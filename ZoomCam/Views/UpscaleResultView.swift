import SwiftUI

struct UpscaleResultView: View {
    let image: UIImage
    let info: UpscaleInfo?
    let onDismiss: () -> Void

    @State private var showingSaveAlert = false
    @State private var comparisonMode = false
    @State private var sliderValue: CGFloat = 0.5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.yellow)
                    .padding()

                    Spacer()

                    Text("AI Upscaled")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: saveImage) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title2)
                            .foregroundColor(.yellow)
                    }
                    .padding()
                }

                // Info banner
                if let info = info {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)

                        Text(info.description)
                            .font(.caption)
                            .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.2))
                }

                // Image display
                if comparisonMode {
                    comparisonView
                } else {
                    ScrollView([.horizontal, .vertical]) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }

                // Bottom controls
                VStack(spacing: 12) {
                    // View mode toggle
                    HStack(spacing: 20) {
                        Button(action: { comparisonMode = false }) {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.title3)
                                Text("Full")
                                    .font(.caption2)
                            }
                            .foregroundColor(!comparisonMode ? .yellow : .gray)
                        }

                        Button(action: { comparisonMode = true }) {
                            VStack {
                                Image(systemName: "square.split.2x2")
                                    .font(.title3)
                                Text("Compare")
                                    .font(.caption2)
                            }
                            .foregroundColor(comparisonMode ? .yellow : .gray)
                        }

                        Spacer()

                        // Share button
                        Button(action: shareImage) {
                            VStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3)
                                Text("Share")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)

                    // Save buttons
                    HStack(spacing: 12) {
                        Button(action: saveImage) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save to Photos")
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.8))
            }
        }
        .alert("Image Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The upscaled image has been saved to your photo library.")
        }
    }

    private var comparisonView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Upscaled image (background)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // Original image (overlay with clip)
                Rectangle()
                    .fill(Color.black)
                    .frame(width: geometry.size.width * (1 - sliderValue))
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        sliderValue = max(0, min(1, value.location.x / geometry.size.width))
                    }
            )
        }
        .overlay(
            // Slider line
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 2)
                    .offset(x: geometry.size.width * sliderValue - 1)
            }
        )
    }

    private func saveImage() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showingSaveAlert = true
    }

    private func shareImage() {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
