import SwiftUI
import AVFoundation
import UIKit

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.session = session
    }

    // MARK: - UIView subclass

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        var session: AVCaptureSession? {
            didSet { previewLayer.session = session }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = bounds
        }
    }
}
