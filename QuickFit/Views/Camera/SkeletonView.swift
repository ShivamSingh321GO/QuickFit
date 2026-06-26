//
//  SkeletonView.swift
//  QuickFit
//

import SwiftUI

struct SkeletonView: View {
    let pose: DetectedBodyPose?

    var body: some View {
        Canvas { context, size in
            guard let pose else { return }
            
            func pt(_ joint: DetectedJoint?) -> CGPoint? {
                guard let joint, joint.confidence > 0.15 else { return nil }
                // Vision normalized coordinates (bottom-left origin) -> SwiftUI view space (top-left origin)
                return CGPoint(x: joint.point.x * size.width, y: (1.0 - joint.point.y) * size.height)
            }
            
            let neck = pt(pose.neck)
            let lShoulder = pt(pose.leftShoulder)
            let rShoulder = pt(pose.rightShoulder)
            let lHip = pt(pose.leftHip)
            let rHip = pt(pose.rightHip)
            let lAnkle = pt(pose.leftAnkle)
            let rAnkle = pt(pose.rightAnkle)
            let lEar = pt(pose.leftEar)
            let rEar = pt(pose.rightEar)
            
            // Draw Bone Segments
            func drawBone(from p1: CGPoint?, to p2: CGPoint?, color: Color = .cyan) {
                guard let p1, let p2 else { return }
                var path = Path()
                path.move(to: p1)
                path.addLine(to: p2)
                
                // Outer glow
                context.stroke(path, with: .color(color.opacity(0.4)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                // Inner core
                context.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            
            // Spine & Shoulders
            drawBone(from: lEar, to: neck, color: .yellow)
            drawBone(from: rEar, to: neck, color: .yellow)
            drawBone(from: lShoulder, to: neck)
            drawBone(from: rShoulder, to: neck)
            
            // Torso box
            drawBone(from: lShoulder, to: lHip)
            drawBone(from: rShoulder, to: rHip)
            drawBone(from: lHip, to: rHip)
            
            // Legs
            drawBone(from: lHip, to: lAnkle, color: .green)
            drawBone(from: rHip, to: rAnkle, color: .green)
            
            // Draw Joint Nodes
            let allPoints = [neck, lShoulder, rShoulder, lHip, rHip, lAnkle, rAnkle, lEar, rEar].compactMap { $0 }
            for point in allPoints {
                let rect = CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12)
                context.fill(Path(ellipseIn: rect.insetBy(dx: -4, dy: -4)), with: .color(.cyan.opacity(0.5)))
                context.fill(Path(ellipseIn: rect), with: .color(.white))
            }
        }
        .allowsHitTesting(false)
    }
}
