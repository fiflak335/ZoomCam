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
                    Button(action: onDismiss) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Done")
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.yellow)
                    }
                    .padding()

                    Spacer()

                    Text("AI Enhanced")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: saveImage) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title3)
                            .foregroundColor(.yellow)
                    }
                    .padding()
                }
                .background(.ultraThinMaterial)

                // Info banner
                if let info = info {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)

                        Text(info.description)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.yellow.opacity(0.15))
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
                    HStack(spacing: 16) {
                        Button(action: { withAnimation { comparisonMode = false } }) {
                            VStack(spacing: 4) {
                                Image(systemName: "photo")
                                    .font(.title3)
                                Text("Full")
                                    .font(.caption2)
                            }
                            .foregroundColor(!comparisonMode ? .yellow : .white.opacity(0.5))
                        }

                        Button(action: { withAnimation { comparisonMode = true } }) {
                            VStack(spacing: 4) {
                                Image(systemName: "square.split.2x2")
                                    .font(.title3)
                                Text("Compare")
                                    .font(.caption2)
                            }
                            .foregroundColor(comparisonMode ? .yellow : .white.opacity(0.5))
                        }

                        Spacer()

                        // Share button
                        Button(action: shareImage) {
                            VStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3)
                                Text("Share")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 20)

                    // Save button
                    Button(action: saveImage) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down.fill")
                            Text("Save to Photos")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
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
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
            }
        }
        .alert("Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enhanced photo saved to your library")
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
