# ZoomCam - iOS Camera App

A powerful iOS camera app with **100x digital zoom** and **AI-powered image upscaling**.

## Features

### 100x Digital Zoom
- Smooth pinch-to-zoom gesture support
- Quick zoom presets: 1x, 2x, 5x, 10x, 25x, 50x, 100x
- Precise text input for exact zoom levels
- Double-tap to toggle between 1x and 2x
- Real-time zoom indicator overlay

### AI Image Upscaling
- 4x neural network-based upscaling
- CIFilter-powered enhancement pipeline:
  - Luminance sharpening
  - Unsharp mask for edge enhancement
  - Noise reduction for cleaner output
- Side-by-side comparison view
- Processing time and megapixel stats

### Camera Features
- Front/rear camera switching
- Flash/torch control
- High-quality photo capture
- Photo library integration

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.0+

## Building Locally

### Using Xcode
1. Open `ZoomCam.xcodeproj` in Xcode
2. Select a development team in Signing & Capabilities
3. Connect an iOS device
4. Select your device as the build destination
5. Press Cmd+R to build and run

### Command Line
```bash
# Build for device
xcodebuild -project ZoomCam.xcodeproj -scheme ZoomCam -configuration Release -destination 'generic/platform=iOS' CODE_SIGN_IDENTITY="iPhone Distribution"

# Create IPA
mkdir -p Payload
cp -r Build/Release-iphoneos/ZoomCam.app Payload/
zip -r ZoomCam.ipa Payload
```

## Building via GitHub Actions

### Automatic Build
1. Push to `main` or `develop` branch
2. Go to Actions tab in your GitHub repo
3. The workflow will automatically build and upload the IPA

### Manual Build
1. Go to Actions > Build iOS IPA
2. Click "Run workflow"
3. Download the IPA from Artifacts

### Required Secrets (for signed builds)
Add these secrets in your GitHub repo (Settings > Secrets):

| Secret | Description |
|--------|-------------|
| `CERTIFICATE_P12` | Base64-encoded .p12 certificate |
| `CERTIFICATE_PASSWORD` | Password for the .p12 file |
| `PROVISIONING_PROFILE` | Base64-encoded .mobileprovision file |
| `PROVISIONING_PROFILE_UUID` | UUID of the provisioning profile |
| `CODE_SIGN_IDENTITY` | e.g., "iPhone Distribution: Your Name (TEAMID)" |
| `DEVELOPMENT_TEAM` | Your Apple Developer Team ID |

### Without Signing (Ad-Hoc)
The workflow also has a `build-adhoc` job that builds without code signing - useful for testing on devices with Development certificates already installed.

## Project Structure

```
ZoomCam/
├── ZoomCam.xcodeproj/          # Xcode project
├── ZoomCam/
│   ├── ZoomCamApp.swift        # App entry point
│   ├── Models/
│   │   └── AIUpscaler.swift    # AI upscaling engine
│   ├── ViewModels/
│   │   └── CameraManager.swift # Camera session management
│   ├── Views/
│   │   ├── CameraView.swift    # Main camera UI
│   │   ├── ContentView.swift   # Welcome screen
│   │   ├── PreviewView.swift   # Photo preview
│   │   └── UpscaleResultView.swift # Upscaled result view
│   ├── Resources/
│   └── Utils/
├── .github/
│   └── workflows/
│       └── build.yml           # CI/CD pipeline
└── README.md
```

## How AI Upscaling Works

The upscaling process uses a multi-stage pipeline:

1. **Sharpening** - `CISharpenLuminance` enhances edge contrast
2. **Unsharp Mask** - `CIUnsharpMask` improves detail definition
3. **Scaling** - High-quality bilinear interpolation to 4x resolution
4. **Denoising** - `CINoiseReduction` cleans up artifacts

For better results, you can integrate a Core ML model (Real-ESRGAN, etc.) by adding a `.mlmodelc` file to the Resources folder.

## License

MIT License - feel free to use and modify.
