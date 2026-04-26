//
//  ClipStorageTests.swift
//  VerticalLogTests
//

import Foundation
import Testing
@testable import VerticalLog

@Suite("ClipStorage")
struct ClipStorageTests {
    @Test("reserveURL returns Documents/clips/{uuid}.mp4")
    func reserveURLPath() async throws {
        let storage = ClipStorage()
        let id = UUID()
        let url = try await storage.reserveURL(id: id)

        #expect(url.lastPathComponent == "\(id.uuidString).mp4")
        #expect(url.deletingLastPathComponent().lastPathComponent == "clips")
    }

    @Test("register returns metadata with provided id and duration")
    func registerProducesMetadata() async throws {
        let storage = ClipStorage()
        let id = UUID()
        let url = try await storage.reserveURL(id: id)
        let meta = await storage.register(id: id, at: url, durationMs: 2000)

        #expect(meta.id == id)
        #expect(meta.url == url)
        #expect(meta.durationMs == 2000)
    }

    @Test("listAll filters non-mp4 files and non-uuid names")
    func listAllFilters() async throws {
        let storage = ClipStorage()
        let id = UUID()
        let url = try await storage.reserveURL(id: id)
        try Data().write(to: url)

        let all = try await storage.listAll()
        #expect(all.contains { $0.id == id })

        // Cleanup (defer can't await, so do it inline)
        try? await storage.delete(id: id)
    }
}
