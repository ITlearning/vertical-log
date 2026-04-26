//
//  RoomsViewModel.swift
//  VerticalLog
//

import Foundation

@MainActor
@Observable
final class RoomsViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Room])
        case error(String)
    }

    private(set) var state: State = .idle
    var errorMessage: String?

    private let service: RoomsService

    init(service: RoomsService = .shared) {
        self.service = service
    }

    /// Load the user's rooms. Idempotent — safe to call from `.task`.
    func load(force: Bool = false) async {
        if !force, case .loading = state { return }
        if !force, case .loaded = state { return }
        state = .loading
        do {
            let rooms = try await service.list()
            state = .loaded(rooms)
        } catch {
            state = .error(humanReadable(error))
        }
    }

    /// Refresh the list (used after create/join).
    func refresh() async {
        await load(force: true)
    }

    /// Create a new room. Returns the new Room on success; updates state too.
    @discardableResult
    func create(name: String) async -> Room? {
        do {
            let room = try await service.create(name: name)
            // Optimistic prepend. A subsequent refresh will reconcile.
            if case .loaded(var rooms) = state {
                rooms.insert(room, at: 0)
                state = .loaded(rooms)
            }
            return room
        } catch {
            errorMessage = humanReadable(error)
            return nil
        }
    }

    /// Join via invite code. Returns the room ID on success.
    @discardableResult
    func join(code: String) async -> RoomsService.JoinResult? {
        do {
            let result = try await service.join(code: code.uppercased())
            // Refresh in background to pick up the joined room.
            await refresh()
            return result
        } catch {
            errorMessage = humanReadable(error)
            return nil
        }
    }

    var rooms: [Room] {
        if case .loaded(let rooms) = state { return rooms }
        return []
    }

    private func humanReadable(_ error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidResponse: return "서버 응답이 이상해요. 잠시 후 다시 시도해주세요."
            case .httpStatus(let code, let data):
                if let parsed = try? JSONDecoder().decode(ErrorBody.self, from: data) {
                    return mapApiError(code: code, body: parsed)
                }
                return "오류가 발생했어요 (HTTP \(code))."
            }
        }
        return "네트워크 오류가 발생했어요."
    }

    private struct ErrorBody: Decodable {
        let error: String?
        let message: String?
    }

    private func mapApiError(code: Int, body: ErrorBody) -> String {
        switch (code, body.error) {
        case (401, _): return "다시 로그인이 필요해요."
        case (404, "not_found"): return "그런 코드의 방이 없어요. 코드를 다시 확인해주세요."
        case (409, "room_full"): return "방이 가득 찼어요."
        case (400, "invalid_code_length"): return "초대 코드는 6자리예요."
        case (400, _): return body.message ?? "요청이 잘못됐어요."
        default: return body.message ?? "오류가 발생했어요 (HTTP \(code))."
        }
    }
}
