import SwiftUI

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
            LinearGradient(
                colors: [.black, .gray.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // App icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.black)
                }

                Text("ZoomCam")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("100x Zoom + AI Upscaling")
                    .font(.title3)
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "magnifyingglass.circle", title: "100x Digital Zoom", description: "Pinch or use slider for extreme zoom")
                    FeatureRow(icon: "sparkles", title: "AI Enhancement", description: "Upscale photos with neural networks")
                    FeatureRow(icon: "photo.stack", title: "RAW Quality", description: "Capture and process in high quality")
                }
                .padding(.horizontal, 40)

                Spacer()

                if hasCameraPermission {
                    Button(action: { showCamera = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Open Camera")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                } else {
                    VStack(spacing: 12) {
                        Text("Camera permission required")
                            .foregroundColor(.red)

                        Button("Grant Permission") {
                            requestCameraPermission()
                        }
                        .foregroundColor(.yellow)
                    }
                    .padding(.bottom, 40)
                }
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

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 40)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}
