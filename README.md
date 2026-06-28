# QuickFit

**QuickFit** is a next-generation native iOS application designed to bring the traditional fitting room directly to your smartphone. Leveraging Generative AI and Apple's Vision framework, QuickFit empowers users to digitize their wardrobe, stylize custom avatar mannequins, and try on clothes virtually. 

Experience a seamless, photorealistic try-on right on your iPhone without stepping into a store.

## Key Features

- **Wardrobe Manager**: Browse, search, and categorize digitized garments using fast, horizontal bubble filters.
- **Avatars Studio**: Capture your pose live with real-time camera tracking to create a personalized digital mannequin.
- **Virtual Try-On**: Generative AI (Hugging Face IDM-VTON) segments your pose, warps 2D garments to fit your body shape, and blends lighting/shadows realistically.
- **Real-Time Camera Guidance**: Vision framework detects body joints dynamically and provides real-time positioning feedback.
- **Background Removal**: Uses iOS 17 Neural Engine-powered foreground masking to isolate humans and clothes from complex backgrounds seamlessly.
- **Creations History**: Local, SwiftData-backed digital dressing room history displaying your complete AI-generated try-on history.

## Tech Stack

QuickFit is built entirely with modern iOS frameworks and Serverless GPU endpoints:

- **UI & Layout**: SwiftUI
- **Local Database**: SwiftData 
- **Body Tracking & ML**: Vision Framework (`VNDetectHumanBodyPoseRequest`, `VNGenerateForegroundInstanceMaskRequest`)
- **Camera & Hardware**: AVFoundation (`AVCaptureSession`)
- **Image Processing**: CoreImage (Filters & Blending)
- **Networking**: URLSession (Async Networking, Server-Sent Events SSE parsing)
- **Concurrency**: Swift async/await, Task, and background thread execution
- **Generative AI Model**: IDM-VTON via Hugging Face Gradio endpoints

## Setup & Installation

### Prerequisites
- macOS Sonoma or newer
- Xcode 15.0+ (Xcode 15.2+ recommended)
- iOS 17.0+ (Required for advanced Vision Foreground Mask requests; fallbacks to older segmentation models exist but iOS 17+ is highly recommended).
- Apple Developer Account (for on-device testing and camera permissions)

### Step-by-Step Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ShivamSingh321GO/QuickFit.git
   cd QuickFit
   ```

2. **Open the project in Xcode:**
   Open `QuickFit.xcodeproj` in Xcode.
   ```bash
   open QuickFit.xcodeproj
   ```

3. **Configure Signing & Capabilities:**
   - Select the `QuickFit` target in the project navigator.
   - Go to the **Signing & Capabilities** tab.
   - Select your personal or team Apple Developer account under the **Team** dropdown.
   - Ensure the **Bundle Identifier** is unique (e.g., `com.yourname.QuickFit`).

4. **Required Permissions (Info.plist):**
   The app requires the following permissions to function. These are pre-configured in the `Info.plist`, but ensure they remain intact:
   - `NSCameraUsageDescription` (Privacy - Camera Usage Description): "QuickFit needs camera access to capture your avatars and garments."
   - `NSPhotoLibraryAddUsageDescription` (Privacy - Photo Library Additions Usage Description): "QuickFit needs permission to save virtual try-on photos to your gallery."

5. **Build and Run:**
   - Select your physical iOS device (A physical device is recommended over the simulator since AVFoundation camera capture requires real hardware).
   - Hit **Run** (Command + R).

## Performance Optimizations

QuickFit is engineered to maintain a buttery-smooth 60 FPS experience:
- **Vision Sequence Handlers**: Utilizes `VNSequenceRequestHandler` for continuous video parsing rather than re-instantiating image handlers, drastically reducing memory overhead.
- **Frame Throttling**: Implements concurrent frame-drop locks to prevent Neural Engine queue backups during live body tracking.
- **Detached Processing**: Heavy computations like high-res pixel buffer conversions (`.jpegData`) are pushed to `Task.detached` background threads to prevent UI stutters.
- **Real-Time Network Streams**: Uses `URLSession.shared.bytes` to parse Server-Sent Events (SSE) byte-by-byte for instant queue feedback from the AI server without polling blocks.

---

*Transform your wardrobe with QuickFit. Designed and built for the future of digital fashion.*
