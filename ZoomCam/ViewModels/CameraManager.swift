import AVFoundation
import UIKit
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var currentZoom: CGFloat = 1.0
    @Published var maxZoom: CGFloat = 100.0
    @Published var capturedImage: UIImage?
    @Published var torchEnabled = false
    @Published var currentPosition: AVCaptureDevice.Position = .back

    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var videoDevice: AVCaptureDevice?
    private var isConfiguring = false

    override init() {
        super.init()
        setupSession()
    }

    func setupSession() {
        guard !isConfiguring else { return }
        isConfiguring = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            // Remove existing inputs
            for input in self.session.inputs {
                self.session.removeInput(input)
            }

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentPosition) else {
                print("No camera available")
                self.session.commitConfiguration()
                self.isConfiguring = false
                return
            }

            self.videoDevice = device

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                    self.videoDeviceInput = input
                }

                // Remove existing outputs
                for output in self.session.outputs {
                    self.session.removeOutput(output)
                }

                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }

                self.configureZoom()

                self.session.commitConfiguration()

                if !self.session.isRunning {
                    self.session.startRunning()
                }

                DispatchQueue.main.async {
                    self.isSessionRunning = true
                    self.isConfiguring = false
                }
            } catch {
                print("Failed to setup camera: \(error.localizedDescription)")
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.isConfiguring = false
                }
            }
        }
    }

    private func configureZoom() {
        guard let device = videoDevice else { return }

        do {
            try device.lockForConfiguration()
            let maxAvailableZoom = device.activeFormat.videoMaxZoomFactor
            maxZoom = min(maxAvailableZoom, 100.0)
            device.videoZoomFactor = 1.0
            device.unlockForConfiguration()
        } catch {
            print("Failed to configure zoom: \(error)")
        }
    }

    func setZoom(_ zoom: CGFloat) {
        guard let device = videoDevice else { return }
        let clampedZoom = max(1.0, min(zoom, maxZoom))

        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clampedZoom
            device.unlockForConfiguration()

            DispatchQueue.main.async {
                self.currentZoom = clampedZoom
            }
        } catch {
            print("Failed to set zoom: \(error)")
        }
    }

    func smoothZoom(to targetZoom: CGFloat, duration: TimeInterval = 0.3) {
        guard let device = videoDevice else { return }
        let clampedZoom = max(1.0, min(targetZoom, maxZoom))

        let startZoom = device.videoZoomFactor
        let zoomDelta = clampedZoom - startZoom
        let steps: Int = max(1, Int(duration * 60))
        let stepTime = duration / Double(steps)

        DispatchQueue.global(qos: .userInteractive).async {
            for i in 0...steps {
                let progress = Double(i) / Double(steps)
                let eased = self.easeInOut(progress)
                let zoom = startZoom + zoomDelta * eased

                do {
                    try device.lockForConfiguration()
                    device.videoZoomFactor = zoom
                    device.unlockForConfiguration()
                } catch {
                    print("Zoom error: \(error)")
                }

                DispatchQueue.main.async {
                    self.currentZoom = zoom
                }

                if i < steps {
                    Thread.sleep(forTimeInterval: stepTime)
                }
            }
        }
    }

    private func easeInOut(_ t: Double) -> Double {
        return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }

    func toggleTorch() {
        guard let device = videoDevice, device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = torchEnabled ? .off : .on
            device.unlockForConfiguration()
            torchEnabled.toggle()
        } catch {
            print("Torch error: \(error)")
        }
    }

    func capturePhoto() {
        guard session.isRunning else {
            print("Session not running")
            return
        }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = torchEnabled ? .on : .off
        settings.photoQualityPrioritization = .quality

        // Unique ID for each photo settings
        settings.uniqueID = Date().timeIntervalSince1970

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func switchCamera() {
        guard !isConfiguring else { return }
        isConfiguring = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()

            self.currentPosition = self.currentPosition == .back ? .front : .back

            // Remove current input
            if let currentInput = self.videoDeviceInput {
                self.session.removeInput(currentInput)
            }

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentPosition) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.isConfiguring = false
                }
                return
            }

            self.videoDevice = device

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                    self.videoDeviceInput = input
                }
            } catch {
                print("Failed to switch camera: \(error)")
            }

            self.configureZoom()
            self.session.commitConfiguration()

            DispatchQueue.main.async {
                self.isConfiguring = false
                self.torchEnabled = false
            }
        }
    }

    func zoomToFit() {
        smoothZoom(to: 1.0)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Photo capture error: \(error.localizedDescription)")
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("Failed to create image from photo data")
            return
        }

        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}
