//
//  RoomsService.swift
//  VerticalLog
//

import Foundation

actor RoomsService {
    static let shared = RoomsService()

    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    /// GET /api/rooms — rooms the authenticated user is a member of.
    func list() async throws -> [Room] {
        struct Response: Decodable, Sendable {
            let rooms: [Room]
        }
        let response: Response = try await api.get("rooms")
        return response.rooms
    }

    /// POST /api/rooms { name } — create a new room (caller becomes owner).
    /// Returns the new room (already includes invite_code + member_count=1).
    func create(name: String) async throws -> Room {
        struct Body: Encodable { let name: String }
        return try await api.post("rooms", body: Body(name: name))
    }

    /// POST /api/rooms/join { code } — idempotent join.
    func join(code: String) async throws -> JoinResult {
        struct Body: Encodable { let code: String }
        return try await api.post("rooms/join", body: Body(code: code))
    }

    struct JoinResult: Decodable, Sendable {
        let roomId: UUID
        let name: String
        let memberCount: Int
        let alreadyMember: Bool
    }
}
