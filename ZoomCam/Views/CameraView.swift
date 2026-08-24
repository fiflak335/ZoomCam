import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var upscaler = AIUpscaler()
    @StateObject private var settings = SettingsManager.shared
    @State private var showPreview = false
    @State private var showUpscaleResult = false
    @State private var upscaledImage: UIImage?
    @State private var upscaleInfo: UpscaleInfo?
    @State private var isCapturing = false
    @State private var flashOpacity: Double = 0
    @State private var showSettings = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var pinchStartZoom: CGFloat = 1.0
    @State private var zoomText: String = "1x"

    let zoomLevels: [CGFloat] = [0.5, 1, 2, 5, 10, 25, 50, 100]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Camera preview
                GeometryReader { geometry in
                    ZStack {
                        CameraPreviewView(session: cameraManager.session)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()

                        // Flash overlay
                        Color.white
                            .opacity(flashOpacity)
                            .ignoresSafeArea()

                        // Grid overlay
                        if settings.showGrid {
                            GridView()
                        }

                        // Zoom level indicator
                        if cameraManager.currentZoom > 1 {
                            VStack {
                                Spacer()
                                    .frame(height: 20)
                                Text(zoomText)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                                Spacer()
                            }
                        }
                    }
                }
                .gesture(
                    MagnificationGesture(minimumScaleDelta: 0)
                        .onChanged { value in
                            let newZoom = pinchStartZoom * value
                            cameraManager.setZoom(newZoom)
                            updateZoomText()
                        }
                        .onEnded { _ in
                            pinchStartZoom = cameraManager.currentZoom
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if cameraManager.currentZoom > 1.0 {
                            cameraManager.smoothZoom(to: 1.0)
                        } else {
                            cameraManager.smoothZoom(to: 2.0)
                        }
                        updateZoomText()
                    }
                }

                // Bottom controls
                bottomControls
            }
        }
        .sheet(isPresented: $showPreview) {
            if let image = cameraManager.capturedImage {
                PreviewView(
                    image: image,
                    upscaler: upscaler,
                    settings: settings,
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
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings)
        }
        .onAppear {
            updateZoomText()
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 24) {
            // Zoom lens selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(zoomLevels, id: \.self) { zoom in
                        ZoomLensButton(
                            zoom: zoom,
                            currentZoom: cameraManager.currentZoom,
                            isSelected: abs(cameraManager.currentZoom - zoom) < 0.3
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                cameraManager.smoothZoom(to: zoom)
                                updateZoomText()
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Main controls
            HStack(spacing: 0) {
                // Thumbnail / Gallery
                if let image = cameraManager.capturedImage {
                    Button(action: { showPreview = true }) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                } else {
                    Button(action: { showPreview = true }) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    }
                }

                Spacer()

                // Capture button
                Button(action: capturePhoto) {
                    ZStack {
                        // Outer ring
                        Circle()
                            .stroke(.white, lineWidth: 4)
                            .frame(width: 76, height: 76)

                        // Inner circle
                        Circle()
                            .fill(isCapturing ? .gray : .white)
                            .frame(width: 64, height: 64)
                            .scaleEffect(isCapturing ? 0.9 : 1.0)
                    }
                }
                .disabled(isCapturing)

                Spacer()

                // Settings button
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 24)

            // Mode selector
            HStack(spacing: 24) {
                // Torch
                Button(action: {
                    withAnimation { cameraManager.toggleTorch() }
                }) {
                    Image(systemName: cameraManager.torchEnabled ? "bolt.fill" : "bolt.slash.fill")
                        .font(.body)
                        .foregroundColor(cameraManager.torchEnabled ? .yellow : .white)
                        .frame(width: 44, height: 44)
                        .background(cameraManager.torchEnabled ? .yellow.opacity(0.2) : .ultraThinMaterial)
                        .clipShape(Circle())
                }

                Spacer()

                // Camera flip
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        cameraManager.switchCamera()
                    }
                }) {
                    Image(systemName: "camera.rotate.fill")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }

    private func capturePhoto() {
        guard !isCapturing else { return }

        isCapturing = true

        if settings.hapticFeedback {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }

        // Flash animation
        withAnimation(.easeOut(duration: 0.1)) {
            flashOpacity = 0.5
        }
        withAnimation(.easeIn(duration: 0.2).delay(0.1)) {
            flashOpacity = 0
        }

        cameraManager.capturePhoto()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCapturing = false
            if cameraManager.capturedImage != nil {
                showPreview = true
            }
        }
    }

    private func updateZoomText() {
        let zoom = cameraManager.currentZoom
        if zoom < 1 {
            zoomText = String(format: "%.1fx", zoom)
        } else if zoom == floor(zoom) {
            zoomText = "\(Int(zoom))x"
        } else {
            zoomText = String(format: "%.1fx", zoom)
        }
    }
}

struct ZoomLensButton: View {
    let zoom: CGFloat
    let currentZoom: CGFloat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(zoom < 1 ? String(format: "%.1g", zoom) : "\(Int(zoom))")
                .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .black : .white)
                .frame(width: 44, height: 32)
                .background(isSelected ? .white : .clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        }
    }
}

struct GridView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            Path { path in
                // Vertical lines
                path.move(to: CGPoint(x: width / 3, y: 0))
                path.addLine(to: CGPoint(x: width / 3, y: height))
                path.move(to: CGPoint(x: (width / 3) * 2, y: 0))
                path.addLine(to: CGPoint(x: (width / 3) * 2, y: height))

                // Horizontal lines
                path.move(to: CGPoint(x: 0, y: height / 3))
                path.addLine(to: CGPoint(x: width, y: height / 3))
                path.move(to: CGPoint(x: 0, y: (height / 3) * 2))
                path.addLine(to: CGPoint(x: width, y: (height / 3) * 2))
            }
            .stroke(.white.opacity(0.3), lineWidth: 0.5)
        }
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
