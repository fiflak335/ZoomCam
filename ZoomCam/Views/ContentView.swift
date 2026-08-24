import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var showCamera = false
    @State private var hasCameraPermission = false

    var body: some View {
        ZStack {
            if showCamera {
                CameraView()
                    .ignoresSafeArea()
            } else {
                welcomeScreen
            }
        }
        .onAppear {
            checkCameraPermission()
        }
    }

    private var welcomeScreen: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.15, green: 0.1, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                // App Icon
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow.opacity(0.3), .orange.opacity(0.1), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)

                    // Icon background
                    RoundedRectangle(cornerRadius: 36)
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .yellow.opacity(0.5), radius: 20, y: 10)

                    // Icon symbol
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundColor(.black)
                }

                Spacer()
                    .frame(height: 32)

                // Title
                Text("ZoomCam")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()
                    .frame(height: 8)

                // Subtitle
                Text("100x Zoom + AI Upscaling")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()
                    .frame(height: 48)

                // Feature cards
                VStack(spacing: 12) {
                    FeatureCard(
                        icon: "magnifyingglass.circle.fill",
                        title: "100x Digital Zoom",
                        description: "Pinch, tap, or use lens selector",
                        color: .blue
                    )

                    FeatureCard(
                        icon: "sparkles",
                        title: "AI Enhancement",
                        description: "Upscale photos up to 8x",
                        color: .purple
                    )

                    FeatureCard(
                        icon: "camera.aperture",
                        title: "Pro Controls",
                        description: "Grid, torch, quality settings",
                        color: .green
                    )
                }
                .padding(.horizontal, 32)

                Spacer()

                // CTA Button
                if hasCameraPermission {
                    Button(action: { showCamera = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.title3)

                            Text("Open Camera")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .yellow.opacity(0.4), radius: 20, y: 10)
                    }
                    .padding(.horizontal, 32)
                } else {
                    Button(action: requestCameraPermission) {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.title3)

                            Text("Grant Camera Permission")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()
                    .frame(height: 40)
            }
        }
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasCameraPermission = true
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    hasCameraPermission = granted
                    showCamera = granted
                }
            }
        default:
            hasCameraPermission = false
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                hasCameraPermission = granted
                if granted {
                    showCamera = true
                }
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}
