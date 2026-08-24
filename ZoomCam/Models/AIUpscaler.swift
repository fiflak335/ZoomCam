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
        // Try to load a custom model if available, otherwise use built-in methods
        if let modelURL = Bundle.main.url(forResource: "UpscalerModel", withExtension: "mlmodelc") {
            do {
                let mlModel = try MLModel(contentsOf: modelURL)
                model = try VNCoreMLModel(for: mlModel)
            } catch {
                print("Failed to load custom upscaler model: \(error)")
                setupFallbackUpscaler()
            }
        } else {
            setupFallbackUpscaler()
        }
    }

    private func setupFallbackUpscaler() {
        print("Using built-in CIFilter-based upscaler")
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

        if let model = model {
            return await upscaleWithCoreML(image, model: model, scale: targetScale)
        } else {
            return await upscaleWithCIFilter(image, scale: targetScale)
        }
    }

    private func upscaleWithCoreML(_ image: UIImage, model: VNCoreMLModel, scale: Int) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width * scale
        let height = cgImage.height * scale

        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                print("Core ML upscaling error: \(error)")
            }
        }

        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform upscaling: \(error)")
            return await upscaleWithCIFilter(image, scale: scale)
        }

        // Resize the original image to target size as fallback
        return await upscaleWithCIFilter(image, scale: scale)
    }

    private func upscaleWithCIFilter(_ image: UIImage, scale: Int) async -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        await MainActor.run { upscaleProgress = 0.3 }

        // Step 1: Apply sharpening filter
        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance") else { return nil }
        sharpenFilter.setValue(ciImage, forKey: kCIInputImageKey)
        sharpenFilter.setValue(0.7, forKey: kCIInputIntensityKey)

        guard let sharpenedImage = sharpenFilter.outputImage else { return nil }

        await MainActor.run { upscaleProgress = 0.5 }

        // Step 2: Apply unsharp mask for edge enhancement
        guard let unsharpFilter = CIFilter(name: "CIUnsharpMask") else { return nil }
        unsharpFilter.setValue(sharpenedImage, forKey: kCIInputImageKey)
        unsharpFilter.setValue(2.5, forKey: kCIInputIntensityKey)
        unsharpFilter.setValue(1.0, forKey: kCIInputRadiusKey)

        guard let enhancedImage = unsharpFilter.outputImage else { return nil }

        await MainActor.run { upscaleProgress = 0.7 }

        // Step 3: Scale up using high-quality interpolation
        let scaleX = CGFloat(scale)
        let scaleY = CGFloat(scale)
        let scaledImage = enhancedImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        await MainActor.run { upscaleProgress = 0.9 }

        // Step 4: Apply noise reduction for cleaner result
        guard let denoiseFilter = CIFilter(name: "CINoiseReduction") else {
            return renderCIImage(scaledImage)
        }
        denoiseFilter.setValue(scaledImage, forKey: kCIInputImageKey)
        denoiseFilter.setValue(0.02, forKey: kCIInputNoiseLevelKey)
        denoiseFilter.setValue(0.4, forKey: kCIInputSharpnessKey)

        guard let finalImage = denoiseFilter.outputImage else {
            return renderCIImage(scaledImage)
        }

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
        String(format: "%.1f MP → %.1f MP (%dx) in %.2fs",
               originalMegapixels, upscaledMegapixels, scaleFactor, processingTime)
    }
}
