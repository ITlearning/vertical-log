import Foundation

// MARK: - User

struct User: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let displayName: String
    let createdAt: Date
}

// MARK: - Room

struct Room: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let inviteCode: String
    let memberCount: Int
    let createdAt: Date
}

// MARK: - Clip

struct Clip: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let roomID: UUID
    let authorID: UUID
    let authorDisplayName: String
    let blobURL: URL
    let durationMs: Int
    let capturedAt: Date
}

// MARK: - Compile

struct DailyCompile: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let roomID: UUID
    let date: Date

    /// In-app long vlog (≤9.6분)
    let longURL: URL?

    /// CAGL share-ready, ≤24초, IG/TikTok/YT Shorts safe
    let shareReadyURL: URL?

    let status: CompileStatus
}

enum CompileStatus: String, Codable, Sendable {
    case pending
    case processing
    case ready
    case failed
}

// MARK: - Message (V0 chat)

struct Message: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let roomID: UUID
    let senderID: UUID
    let body: String?
    let clipID: UUID?
    let createdAt: Date
}
