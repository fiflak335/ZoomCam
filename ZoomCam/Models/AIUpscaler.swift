import CoreML
import Vision
import UIKit

class AIUpscaler: ObservableObject {
    @Published var isProcessing = false
    @Published var upscaleProgress: Float = 0

    private var model: VNCoreMLModel?

    init() {
        loadModel()
    }

    private func loadModel() {
        if let modelURL = Bundle.main.url(forResource: "UpscalerModel", withExtension: "mlmodelc") {
            do {
                let mlModel = try MLModel(contentsOf: modelURL)
                model = try VNCoreMLModel(for: mlModel)
            } catch {
                print("Failed to load custom upscaler model: \(error)")
            }
        }
    }

    func upscaleImage(_ image: UIImage, targetScale: Int = 4) async -> UIImage? {
        await MainActor.run {
            isProcessing = true
            upscaleProgress = 0
        }

        defer {
            Task { @MainActor in
                isProcessing = false
                upscaleProgress = 1.0
            }
        }

        return await upscaleWithCIFilter(image, scale: targetScale)
    }

    private func upscaleWithCIFilter(_ image: UIImage, scale: Int) async -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        await MainActor.run { upscaleProgress = 0.2 }

        // Step 1: Sharpen luminance
        let sharpenFilter = CIFilter(name: "CISharpenLuminance")
        sharpenFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        sharpenFilter?.setValue(0.7, forKey: kCIInputIntensityKey)

        guard let sharpenedImage = sharpenFilter?.outputImage else { return nil }

        await MainActor.run { upscaleProgress = 0.4 }

        // Step 2: Unsharp mask
        let unsharpFilter = CIFilter(name: "CIUnsharpMask")
        unsharpFilter?.setValue(sharpenedImage, forKey: kCIInputImageKey)
        unsharpFilter?.setValue(2.5, forKey: kCIInputIntensityKey)
        unsharpFilter?.setValue(1.0, forKey: kCIInputRadiusKey)

        guard let enhancedImage = unsharpFilter?.outputImage else { return nil }

        await MainActor.run { upscaleProgress = 0.6 }

        // Step 3: Scale up
        let scaleX = CGFloat(scale)
        let scaleY = CGFloat(scale)
        let scaledImage = enhancedImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        await MainActor.run { upscaleProgress = 0.8 }

        // Step 4: Adjust color and contrast
        let colorFilter = CIFilter(name: "CIColorControls")
        colorFilter?.setValue(scaledImage, forKey: kCIInputImageKey)
        colorFilter?.setValue(1.05, forKey: kCIInputContrastKey)
        colorFilter?.setValue(0.02, forKey: kCIInputSaturationKey)

        guard let finalImage = colorFilter?.outputImage else {
            return renderCIImage(scaledImage)
        }

        await MainActor.run { upscaleProgress = 0.9 }

        return renderCIImage(finalImage)
    }

    private func renderCIImage(_ ciImage: CIImage) -> UIImage? {
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let outputCGImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: outputCGImage, scale: 1.0, orientation: .up)
    }

    func upscaleImageWithDetails(_ image: UIImage) async -> (upscaled: UIImage, details: UpscaleInfo)? {
        let startTime = Date()
        let originalSize = image.size
        let originalMegapixels = (originalSize.width * originalSize.height) / 1_000_000

        guard let upscaled = await upscaleImage(image, targetScale: 4) else { return nil }

        let elapsed = Date().timeIntervalSince(startTime)
        let upscaledSize = upscaled.size
        let upscaledMegapixels = (upscaledSize.width * upscaledSize.height) / 1_000_000

        let info = UpscaleInfo(
            originalSize: originalSize,
            upscaledSize: upscaledSize,
            originalMegapixels: originalMegapixels,
            upscaledMegapixels: upscaledMegapixels,
            processingTime: elapsed,
            scaleFactor: 4
        )

        return (upscaled, info)
    }
}

struct UpscaleInfo {
    let originalSize: CGSize
    let upscaledSize: CGSize
    let originalMegapixels: Double
    let upscaledMegapixels: Double
    let processingTime: TimeInterval
    let scaleFactor: Int

    var description: String {
        String(format: "%.1f MP -> %.1f MP (%dx) in %.2fs",
               originalMegapixels, upscaledMegapixels, scaleFactor, processingTime)
    }
}
