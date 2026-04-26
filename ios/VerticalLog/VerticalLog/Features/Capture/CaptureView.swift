//
//  CaptureView.swift
//  VerticalLog
//

import AVFoundation
import SwiftUI
import UIKit

struct CaptureView: View {
    @State private var viewModel = CaptureViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreview(session: viewModel.session)
                .aspectRatio(9.0/16.0, contentMode: .fit)
                .clipped()
                .ignoresSafeArea()

            VStack {
                Spacer()
                statusOverlay
                recordButton
                    .padding(.bottom, 48)
            }
        }
        .task { await viewModel.bootstrap() }
        .onDisappear { viewModel.tearDown() }
    }

    // MARK: - Status overlay

    @ViewBuilder
    private var statusOverlay: some View {
        switch viewModel.state {
        case .configuring:
            label("카메라 켜는 중...")
        case .recording(let remaining):
            HStack(spacing: 6) {
                Circle().fill(.red).frame(width: 10, height: 10)
                Text(String(format: "REC  %.1fs", remaining))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(.black.opacity(0.5), in: Capsule())
        case .saving:
            label("저장 중...")
        case .error(let message):
            label("오류: \(message)").foregroundStyle(.red)
        case .permissionDenied:
            permissionPrompt
        case .unconfigured, .ready:
            EmptyView()
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(.black.opacity(0.5), in: Capsule())
    }

    private var permissionPrompt: some View {
        VStack(spacing: 12) {
            Text("카메라 권한이 필요해요")
                .font(.headline).foregroundStyle(.white)
            Text("설정에서 카메라 접근을 허용해주세요")
                .font(.caption).foregroundStyle(.white.opacity(0.7))
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("설정으로 이동")
                    .padding(.horizontal, 20).padding(.vertical, 8)
                    .background(.white, in: Capsule())
                    .foregroundStyle(.black)
            }
        }
    }

    // MARK: - Record button

    private var recordButton: some View {
        Button(action: viewModel.tapRecord) {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 84, height: 84)
                Circle()
                    .fill(isRecording ? Color.red : Color.white)
                    .frame(width: isRecording ? 32 : 64, height: isRecording ? 32 : 64)
                    .clipShape(RoundedRectangle(cornerRadius: isRecording ? 6 : 32))
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
            }
        }
        .disabled(!canRecord)
        .opacity(canRecord ? 1 : 0.4)
    }

    private var isRecording: Bool {
        if case .recording = viewModel.state { return true }
        return false
    }

    private var canRecord: Bool {
        switch viewModel.state {
        case .ready, .recording: return true
        default: return false
        }
    }
}

// MARK: - Camera preview (UIKit bridge)

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        if let connection = view.videoPreviewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

#Preview {
    CaptureView()
}
