import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var upscaler = AIUpscaler()
    @State private var zoomScale: CGFloat = 1.0
    @State private var showPreview = false
    @State private var showUpscaleResult = false
    @State private var upscaledImage: UIImage?
    @State private var upscaleInfo: UpscaleInfo?
    @State private var zoomText = "1.0x"
    @State private var pinchStartZoom: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                // Camera preview
                cameraPreview
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 8)

                // Zoom slider area
                zoomControls

                // Bottom controls
                bottomBar
            }

            // Zoom indicator overlay
            if cameraManager.currentZoom > 1.0 {
                zoomIndicator
            }
        }
        .sheet(isPresented: $showPreview) {
            if let image = cameraManager.capturedImage {
                PreviewView(
                    image: image,
                    upscaler: upscaler,
                    onRetake: {
                        showPreview = false
                        cameraManager.capturedImage = nil
                    },
                    onUpscaled: { upscaled, info in
                        upscaledImage = upscaled
                        upscaleInfo = info
                        showPreview = false
                        showUpscaleResult = true
                    }
                )
            }
        }
        .sheet(isPresented: $showUpscaleResult) {
            if let image = upscaledImage {
                UpscaleResultView(
                    image: image,
                    info: upscaleInfo,
                    onDismiss: {
                        showUpscaleResult = false
                        upscaledImage = nil
                        upscaleInfo = nil
                    }
                )
            }
        }
        .onAppear {
            zoomText = String(format: "%.1fx", cameraManager.currentZoom)
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: { cameraManager.toggleTorch() }) {
                Image(systemName: cameraManager.torchEnabled ? "bolt.fill" : "bolt.slash")
                    .font(.title2)
                    .foregroundColor(cameraManager.torchEnabled ? .yellow : .white)
            }
            .padding()

            Spacer()

            Text("ZoomCam")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Button(action: { cameraManager.switchCamera() }) {
                Image(systemName: "camera.rotate")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .padding()
        }
        .background(Color.black.opacity(0.6))
    }

    private var cameraPreview: some View {
        CameraPreviewView(session: cameraManager.session)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(4/3, contentMode: .fit)
            .gesture(
                MagnificationGesture(minimumScaleDelta: 0)
                    .onChanged { value in
                        let newZoom = pinchStartZoom * value
                        cameraManager.setZoom(newZoom)
                        zoomText = String(format: "%.1fx", cameraManager.currentZoom)
                    }
                    .onEnded { value in
                        pinchStartZoom = cameraManager.currentZoom
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if cameraManager.currentZoom > 1.0 {
                        cameraManager.smoothZoom(to: 1.0)
                        zoomText = "1.0x"
                    } else {
                        cameraManager.smoothZoom(to: 2.0)
                        zoomText = "2.0x"
                    }
                }
            }
    }

    private var zoomControls: some View {
        VStack(spacing: 8) {
            // Quick zoom buttons
            HStack(spacing: 12) {
                ForEach([1.0, 2.0, 5.0, 10.0, 25.0, 50.0, 100.0], id: \.self) { zoom in
                    ZoomButton(zoom: zoom, currentZoom: cameraManager.currentZoom) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            cameraManager.smoothZoom(to: zoom)
                            zoomText = String(format: "%.0fx", zoom)
                        }
                    }
                }
            }
            .padding(.horizontal)

            // Slider
            HStack {
                Text("1x")
                    .font(.caption)
                    .foregroundColor(.gray)

                Slider(
                    value: Binding(
                        get: { cameraManager.currentZoom },
                        set: { newValue in
                            cameraManager.setZoom(newValue)
                            zoomText = String(format: "%.1fx", newValue)
                        }
                    ),
                    in: 1...cameraManager.maxZoom,
                    step: 0.1
                )
                .accentColor(.yellow)

                Text("\(Int(cameraManager.maxZoom))x")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)

            // Text input for precise zoom
            HStack {
                Text("Zoom:")
                    .font(.caption)
                    .foregroundColor(.gray)

                TextField("1.0", text: $zoomText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .multilineTextAlignment(.center)
                    .onSubmit {
                        if let zoomValue = Float(zoomText.replacingOccurrences(of: "x", with: "")) {
                            cameraManager.smoothZoom(to: CGFloat(zoomValue))
                        }
                    }

                Text("x")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
    }

    private var bottomBar: some View {
        HStack(spacing: 40) {
            // Gallery preview
            if let image = cameraManager.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 2)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
            }

            // Capture button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                cameraManager.capturePhoto()
                showPreview = true
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 70, height: 70)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                }
            }

            // Spacer for symmetry
            Spacer()
                .frame(width: 50)
        }
        .padding(.vertical, 20)
        .background(Color.black.opacity(0.6))
    }

    private var zoomIndicator: some View {
        VStack {
            Spacer()
                .frame(height: 120)

            Text(zoomText)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.7))
                )
                .transition(.opacity)
        }
    }
}

struct ZoomButton: View {
    let zoom: CGFloat
    let currentZoom: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(Int(zoom))x")
                .font(.caption)
                .fontWeight(isActive ? .bold : .regular)
                .foregroundColor(isActive ? .black : .white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isActive ? Color.yellow : Color.gray.opacity(0.5))
                )
        }
    }

    private var isActive: Bool {
        abs(currentZoom - zoom) < 0.5
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

class CameraPreviewUIView: UIView {
    var session: AVCaptureSession?

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer? {
        return layer as? AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        previewLayer?.videoGravity = .resizeAspectFill
    }

    func setup() {
        guard let session = session else { return }
        let preview = layer as! AVCaptureVideoPreviewLayer
        preview.session = session
        preview.videoGravity = .resizeAspectFill
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        setup()
    }
}
