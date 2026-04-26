//
//  ClipStorage.swift
//  VerticalLog
//
//  Local file management for captured 9:16 clips. Saves into
//  ~Documents/clips/{uuid}.mp4. Sprint 2+ will queue these for upload.
//

import Foundation

struct ClipMetadata: Hashable, Sendable {
    let id: UUID
    let url: URL
    let durationMs: Int
    let capturedAt: Date
}

enum ClipStorageError: Error {
    case directoryUnavailable
    case fileNotFound
}

actor ClipStorage {
    static let shared = ClipStorage()

    private let fileManager = FileManager.default

    private var clipsDirectory: URL {
        get throws {
            guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw ClipStorageError.directoryUnavailable
            }
            let clips = docs.appendingPathComponent("clips", isDirectory: true)
            if !fileManager.fileExists(atPath: clips.path) {
                try fileManager.createDirectory(at: clips, withIntermediateDirectories: true)
            }
            return clips
        }
    }

    /// Reserve a destination URL for a new clip. AVCaptureMovieFileOutput
    /// records directly to this URL.
    func reserveURL(id: UUID = UUID()) throws -> URL {
        try clipsDirectory.appendingPathComponent("\(id.uuidString).mp4")
    }

    /// Probe the saved file and return metadata. Call after recording finishes.
    func register(id: UUID, at url: URL, durationMs: Int) -> ClipMetadata {
        ClipMetadata(id: id, url: url, durationMs: durationMs, capturedAt: Date())
    }

    /// List all locally stored clips (Sprint 2+ uploader iterates over this).
    func listAll() throws -> [ClipMetadata] {
        let dir = try clipsDirectory
        let urls = try fileManager.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )
        return urls.compactMap { url in
            guard url.pathExtension.lowercased() == "mp4",
                  let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent),
                  let attrs = try? url.resourceValues(forKeys: [.creationDateKey]),
                  let created = attrs.creationDate
            else { return nil }
            return ClipMetadata(id: id, url: url, durationMs: 2000, capturedAt: created)
        }
        .sorted { $0.capturedAt > $1.capturedAt }
    }

    /// Delete a clip after successful upload (Sprint 2+).
    func delete(id: UUID) throws {
        let url = try clipsDirectory.appendingPathComponent("\(id.uuidString).mp4")
        guard fileManager.fileExists(atPath: url.path) else {
            throw ClipStorageError.fileNotFound
        }
        try fileManager.removeItem(at: url)
    }
}
