import AVFoundation
import UIKit
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var currentZoom: CGFloat = 1.0
    @Published var maxZoom: CGFloat = 100.0
    @Published var capturedImage: UIImage?
    @Published var isProcessing = false
    @Published var torchEnabled = false

    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var videoDevice: AVCaptureDevice?
    private var currentPosition: AVCaptureDevice.Position = .back

    override init() {
        super.init()
        setupSession()
    }

    func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("No camera available")
            return
        }

        videoDevice = device

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                videoDeviceInput = input
            }

            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }

            configureZoom()

            session.commitConfiguration()
            session.startRunning()

            DispatchQueue.main.async {
                self.isSessionRunning = true
            }
        } catch {
            print("Failed to setup camera: \(error.localizedDescription)")
        }
    }

    private func configureZoom() {
        guard let device = videoDevice else { return }

        do {
            try device.lockForConfiguration()
            let maxAvailableZoom = device.activeFormat.videoMaxZoomFactor
            maxZoom = min(maxAvailableZoom, 100.0)
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
        let steps: Int = Int(duration * 60)
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
        let settings = AVCapturePhotoSettings()
        settings.flashMode = torchEnabled ? .on : .auto
        settings.photoQualityPrioritization = .quality

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func switchCamera() {
        session.beginConfiguration()

        currentPosition = currentPosition == .back ? .front : .back

        if let currentInput = videoDeviceInput {
            session.removeInput(currentInput)
        }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition) else {
            session.commitConfiguration()
            return
        }

        videoDevice = device

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                videoDeviceInput = input
            }
        } catch {
            print("Failed to switch camera: \(error)")
        }

        configureZoom()
        session.commitConfiguration()
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }

        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}
