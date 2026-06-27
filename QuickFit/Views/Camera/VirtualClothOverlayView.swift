//
//  VirtualClothOverlayView.swift
//  QuickFit
//

import SwiftUI

// Computed placement data passed from helper into view builder
private struct GarmentPlacement {
    let center: CGPoint
    let width: CGFloat
    let height: CGFloat
    let tiltRadians: CGFloat
}

struct VirtualClothOverlayView: View {
    let pose: DetectedBodyPose
    let assetName: String
    var isFrontCamera: Bool = true
    
    var body: some View {
        GeometryReader { geo in
            if let placement = computePlacement(in: geo.size) {
                Image(assetName)
                    .resizable()
                    .frame(width: placement.width, height: placement.height)
                    .rotationEffect(.radians(Double(placement.tiltRadians)))
                    .position(placement.center)
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 12)
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Placement Computation (outside @ViewBuilder)
    
    private func computePlacement(in size: CGSize) -> GarmentPlacement? {
        // We need at least neck
        guard let neckJ = pose.neck, neckJ.confidence > 0.005 else { return nil }
        
        let hasLeft = (pose.leftShoulder?.confidence ?? 0) > 0.005
        let hasRight = (pose.rightShoulder?.confidence ?? 0) > 0.005
        
        // We need at least one shoulder
        guard hasLeft || hasRight else { return nil }
        
        let nk = neckJ.screenPoint(in: size, isMirrored: isFrontCamera)
        
        // ── Compute shoulder geometry ──
        let shoulderMid: CGPoint
        let shoulderWidth: CGFloat
        let tiltAngle: CGFloat
        
        if hasLeft && hasRight,
           let lJ = pose.leftShoulder, let rJ = pose.rightShoulder {
            // BOTH SHOULDERS: standard dual-anchor
            let ls = lJ.screenPoint(in: size, isMirrored: isFrontCamera)
            let rs = rJ.screenPoint(in: size, isMirrored: isFrontCamera)
            
            shoulderMid = CGPoint(x: (ls.x + rs.x) / 2.0, y: (ls.y + rs.y) / 2.0)
            shoulderWidth = hypot(ls.x - rs.x, ls.y - rs.y)
            
            // Orientation from shoulder line
            let pLeft = (ls.x < rs.x) ? ls : rs
            let pRight = (ls.x < rs.x) ? rs : ls
            let rawAngle = atan2(pRight.y - pLeft.y, pRight.x - pLeft.x)
            tiltAngle = max(-0.5, min(0.5, rawAngle))
            
        } else {
            // SINGLE-SHOULDER FALLBACK:
            // When holding the phone, one shoulder is occluded.
            // Use neck as the body midline center (it sits on the spine).
            // Estimate shoulder width as 2x the neck-to-visible-shoulder distance.
            let visibleShoulder: CGPoint
            if hasLeft, let lJ = pose.leftShoulder {
                visibleShoulder = lJ.screenPoint(in: size, isMirrored: isFrontCamera)
            } else if let rJ = pose.rightShoulder {
                visibleShoulder = rJ.screenPoint(in: size, isMirrored: isFrontCamera)
            } else {
                return nil
            }
            
            let halfWidth = hypot(visibleShoulder.x - nk.x, visibleShoulder.y - nk.y)
            shoulderWidth = halfWidth * 2.0
            // Center on neck X (spine midline), shoulder Y level
            shoulderMid = CGPoint(x: nk.x, y: visibleShoulder.y)
            // No reliable tilt from single shoulder — keep upright
            tiltAngle = 0
        }
        
        // ── Garment dimensions ──
        let uiImage = UIImage(named: assetName)
        let imageAspect: CGFloat = {
            guard let img = uiImage, img.size.width > 0 else { return 1.0 }
            return img.size.height / img.size.width
        }()
        
        let garmentWidth = max(shoulderWidth * 1.95, 150)
        let garmentHeight = max(garmentWidth * imageAspect, 140)
        
        // ── Vertical placement ──
        let targetY: CGFloat
        if isFrontCamera {
            targetY = nk.y + (garmentHeight * 0.35)
        } else {
            if let lHip = pose.leftHip, let rHip = pose.rightHip,
               lHip.confidence > 0.15, rHip.confidence > 0.15 {
                let lh = lHip.screenPoint(in: size, isMirrored: isFrontCamera)
                let rh = rHip.screenPoint(in: size, isMirrored: isFrontCamera)
                let hipMidY = (lh.y + rh.y) / 2.0
                targetY = (nk.y + hipMidY) / 2.0
            } else {
                targetY = nk.y + (garmentHeight * 0.38)
            }
        }
        
        return GarmentPlacement(
            center: CGPoint(x: shoulderMid.x, y: targetY),
            width: garmentWidth,
            height: garmentHeight,
            tiltRadians: tiltAngle
        )
    }
}

struct CompositeSnapshotView: View {
    let cameraImage: UIImage
    let pose: DetectedBodyPose
    let assetName: String
    let isFrontCamera: Bool
    
    var body: some View {
        ZStack {
            Image(uiImage: cameraImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
            
            VirtualClothOverlayView(
                pose: pose,
                assetName: assetName,
                isFrontCamera: isFrontCamera
            )
        }
        .frame(width: cameraImage.size.width, height: cameraImage.size.height)
        .clipped()
    }
}
