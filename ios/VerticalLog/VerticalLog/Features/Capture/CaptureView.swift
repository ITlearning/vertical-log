//
//  CaptureView.swift
//  VerticalLog
//

import SwiftUI

struct CaptureView: View {
    @State private var isRecording = false

    var body: some View {
        ZStack {
            // TODO(sprint-1): replace with AVCaptureVideoPreviewLayer-backed UIViewRepresentable
            // - 9:16 aspect ratio (portrait orientation locked)
            // - sessionPreset = .hd1920x1080 or .iFrame960x540
            // - 2-second timer auto-stop on tap
            // - Save to local docs dir, queue for upload via APIClient
            Color.black
                .ignoresSafeArea()

            VStack {
                Spacer()
                Text("9:16 카메라 (TODO: AVCaptureSession)")
                    .foregroundStyle(.white.opacity(0.6))
                    .font(.caption)
                Spacer()

                Button(action: toggleRecording) {
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 84, height: 84)
                        .overlay(
                            Circle()
                                .fill(isRecording ? Color.red : Color.white)
                                .frame(width: 64, height: 64)
                                .scaleEffect(isRecording ? 0.7 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isRecording)
                        )
                }
                .padding(.bottom, 60)
            }
        }
    }

    private func toggleRecording() {
        isRecording.toggle()
        // TODO(sprint-1): start AVCaptureSession recording, auto-stop after 2s
    }
}

#Preview {
    CaptureView()
}
