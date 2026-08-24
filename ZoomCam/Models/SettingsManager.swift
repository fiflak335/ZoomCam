import SwiftUI

class SettingsManager: ObservableObject {
    @AppStorage("photoQuality") var photoQuality: PhotoQuality = .high
    @AppStorage("saveOriginal") var saveOriginal: Bool = true
    @AppStorage("showGrid") var showGrid: Bool = false
    @AppStorage("hapticFeedback") var hapticFeedback: Bool = true
    @AppStorage("autoSave") var autoSave: Bool = false
    @AppStorage("upscaleFactor") var upscaleFactor: UpscaleFactor = .fourX
    @AppStorage("preferredZoom") var preferredZoom: Double = 1.0
    @AppStorage("watermarkEnabled") var watermarkEnabled: Bool = false

    static let shared = SettingsManager()
}

enum PhotoQuality: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case maximum = "Maximum"

    var compressionQuality: CGFloat {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 0.8
        case .maximum: return 1.0
        }
    }
}

enum UpscaleFactor: String, CaseIterable {
    case twoX = "2x"
    case fourX = "4x"
    case eightX = "8x"

    var value: Int {
        switch self {
        case .twoX: return 2
        case .fourX: return 4
        case .eightX: return 8
        }
    }
}
