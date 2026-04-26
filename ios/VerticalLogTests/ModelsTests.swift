import Foundation
import Testing
@testable import VerticalLog

@Suite("Codable round-trip")
struct ModelsTests {
    @Test("Room decodes from snake_case JSON")
    func roomDecodesFromSnakeCase() throws {
        let json = """
        {
          "id": "0193c5a4-71b1-7000-8000-000000000001",
          "name": "키오와 친구들",
          "invite_code": "ABC123",
          "member_count": 4,
          "created_at": "2026-04-26T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let room = try decoder.decode(Room.self, from: json)
        #expect(room.name == "키오와 친구들")
        #expect(room.inviteCode == "ABC123")
        #expect(room.memberCount == 4)
    }

    @Test("CompileStatus decodes raw values")
    func compileStatusDecodes() throws {
        let raw = #""processing""#.data(using: .utf8)!
        let status = try JSONDecoder().decode(CompileStatus.self, from: raw)
        #expect(status == .processing)
    }
}
