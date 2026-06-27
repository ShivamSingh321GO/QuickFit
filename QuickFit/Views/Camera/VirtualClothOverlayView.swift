//
//  VirtualClothOverlayView.swift
//  QuickFit
//

import SwiftUI

struct VirtualClothOverlayView: View {
    let pose: DetectedBodyPose
    let assetName: String
    var isFrontCamera: Bool = true
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            
            // Require shoulders and neck for stable garment placement
            if let lShoulderJoint = pose.leftShoulder, let rShoulderJoint = pose.rightShoulder,
               let neckJoint = pose.neck,
               lShoulderJoint.confidence > 0.15 && rShoulderJoint.confidence > 0.15 && neckJoint.confidence > 0.15 {
                
                // Pure SwiftUI aspect-ratio geometry calculation mapping normalized keypoints to view pixels
                let ls = lShoulderJoint.screenPoint(in: size, isMirrored: isFrontCamera)
                let rs = rShoulderJoint.screenPoint(in: size, isMirrored: isFrontCamera)
                
                // Midpoint between shoulders
                let shoulderMid = CGPoint(x: (ls.x + rs.x) / 2.0, y: (ls.y + rs.y) / 2.0)
                let shoulderWidth = hypot(ls.x - rs.x, ls.y - rs.y)
                let nk = neckJoint.screenPoint(in: size, isMirrored: isFrontCamera)
                
                // Uniform anatomical torso center anchor (halfway between collarbone and waistband)
                let targetY: CGFloat = {
                    if let lHip = pose.leftHip, let rHip = pose.rightHip, lHip.confidence > 0.15, rHip.confidence > 0.15 {
                        let lh = lHip.screenPoint(in: size, isMirrored: isFrontCamera)
                        let rh = rHip.screenPoint(in: size, isMirrored: isFrontCamera)
                        let hipMidY = (lh.y + rh.y) / 2.0
                        return (nk.y + hipMidY) / 2.0
                    } else {
                        // Vitruvian anatomical fallback if hips are cropped out of frame
                        return nk.y + (shoulderWidth * 0.95)
                    }
                }()
                
                // Ensure left/right shoulder orientation order never flips garment 180° upside down
                let pLeft = (ls.x < rs.x) ? ls : rs
                let pRight = (ls.x < rs.x) ? rs : ls
                let dx = pRight.x - pLeft.x
                let dy = pRight.y - pLeft.y
                let rawAngle = atan2(dy, dx)
                // Clamp rotation to realistic standing posture (+/- 28°)
                let tiltAngle = max(-0.5, min(0.5, rawAngle))
                
                // Tailored garment width (~1.95x shoulder Euclidean distance perfectly fits sleeves & chest)
                let garmentWidth = max(shoulderWidth * 1.95, 150)
                let placementCenter = CGPoint(x: shoulderMid.x, y: targetY)
                
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: garmentWidth)
                    .rotationEffect(.radians(Double(tiltAngle)))
                    .position(placementCenter)
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 12)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .allowsHitTesting(false) // Let touches pass through to camera UI
    }
}
