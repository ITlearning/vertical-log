//
//  CaptureViewModel.swift
//  VerticalLog
//

import AVFoundation
import Foundation
import UIKit

@MainActor
@Observable
final class CaptureViewModel: NSObject {
    enum State: Equatable {
        case unconfigured
        case configuring
        case ready
        case recording(remaining: Double)
        case saving
        case error(String)
        case permissionDenied(camera: Bool, mic: Bool)
    }

    private(set) var state: State = .unconfigured

    let session = AVCaptureSession()

    private let movieFileOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "vlog.capture.session", qos: .userInitiated)
    private var recordingURL: URL?
    private var recordingID: UUID?
    private var countdownTask: Task<Void, Never>?

    /// Two-second clip duration per design doc.
    static let clipDurationSeconds: Double = 2.0

    // MARK: - Lifecycle

    /// Called from `.task` on every view appear. First time it configures the
    /// session and starts it; on subsequent appears (after a tab switch) it
    /// just resumes the session that was paused by `tearDown()`.
    func bootstrap() async {
        guard state == .unconfigured else {
            resume()
            return
        }
        state = .configuring

        let camOK = await Permissions.requestCamera()
        let micOK = await Permissions.requestMicrophone()
        guard camOK else {
            state = .permissionDenied(camera: false, mic: micOK)
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            do {
                try self.configureSession(includeAudio: micOK)
                self.session.startRunning()
                Task { @MainActor in self.state = .ready }
            } catch {
                Task { @MainActor in self.state = .error(String(describing: error)) }
            }
        }
    }

    /// Resume the (already-configured) session. No-op if already running or
    /// not yet configured.
    func resume() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    /// Pause the session — preview freezes but config is preserved. Recording
    /// in progress is cancelled.
    func tearDown() {
        countdownTask?.cancel()
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: - Recording

    func tapRecord() {
        switch state {
        case .ready:
            startRecording()
        case .recording:
            stopRecording()
        default:
            break
        }
    }

    private func startRecording() {
        let id = UUID()
        Task { @MainActor in
            do {
                let url = try await ClipStorage.shared.reserveURL(id: id)
                self.recordingID = id
                self.recordingURL = url

                self.sessionQueue.async { [weak self] in
                    guard let self else { return }
                    self.movieFileOutput.startRecording(to: url, recordingDelegate: self)
                }
                self.state = .recording(remaining: Self.clipDurationSeconds)
                self.startCountdown()
            } catch {
                self.state = .error(String(describing: error))
            }
        }
    }

    private func startCountdown() {
        countdownTask?.cancel()
        countdownTask = Task { @MainActor in
            let total = Self.clipDurationSeconds
            let start = Date()
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(start)
                let remaining = max(0, total - elapsed)
                if case .recording = self.state {
                    self.state = .recording(remaining: remaining)
                }
                if remaining <= 0 { break }
                try? await Task.sleep(for: .milliseconds(50))
            }
            if !Task.isCancelled, case .recording = self.state {
                self.stopRecording()
            }
        }
    }

    private func stopRecording() {
        countdownTask?.cancel()
        sessionQueue.async { [weak self] in
            guard let self, self.movieFileOutput.isRecording else { return }
            self.movieFileOutput.stopRecording()
        }
        Task { @MainActor in self.state = .saving }
    }

    // MARK: - Session config

    private func configureSession(includeAudio: Bool) throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        if session.sessionPreset != .hd1920x1080 {
            session.sessionPreset = .hd1920x1080
        }

        // Video input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CaptureError.noVideoDevice
        }
        let videoInput = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(videoInput) else { throw CaptureError.cannotAddInput }
        session.addInput(videoInput)

        // Audio input (optional)
        if includeAudio, let mic = AVCaptureDevice.default(for: .audio) {
            if let audioInput = try? AVCaptureDeviceInput(device: mic),
               session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }
        }

        // Output
        guard session.canAddOutput(movieFileOutput) else { throw CaptureError.cannotAddOutput }
        session.addOutput(movieFileOutput)

        if let connection = movieFileOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
    }
}

enum CaptureError: Error {
    case noVideoDevice
    case cannotAddInput
    case cannotAddOutput
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CaptureViewModel: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            guard let id = self.recordingID else {
                self.state = .ready
                return
            }
            if let error {
                self.state = .error(String(describing: error))
                return
            }
            _ = await ClipStorage.shared.register(
                id: id,
                at: outputFileURL,
                durationMs: Int(Self.clipDurationSeconds * 1000)
            )
            self.recordingID = nil
            self.recordingURL = nil
            self.state = .ready
        }
    }
}
