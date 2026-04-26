//
//  APIClient.swift
//  VerticalLog
//

import Foundation

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private(set) var jwt: String?

    init(
        baseURL: URL = .productionAPI,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder

        // Hydrate from Keychain on first init. AuthService.restoreSession()
        // also handles the cold-launch path; this catches background actors
        // that hit APIClient.shared before AuthService runs.
        if let stored = Keychain.load(.sessionToken) {
            self.jwt = stored
        }
    }

    func setJWT(_ token: String?) {
        self.jwt = token
    }

    func get<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        try await request(path: path, method: "GET", body: Optional<Data>.none, as: type)
    }

    func post<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        let data = try encoder.encode(body)
        return try await request(path: path, method: "POST", body: data, as: type)
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        body: Data?,
        as type: T.Type
    ) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let jwt {
            req.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = body

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode, data)
        }
        return try decoder.decode(T.self, from: data)
    }
}

enum APIError: Error {
    case invalidResponse
    case httpStatus(Int, Data)
}

extension URL {
    static let productionAPI = URL(string: "https://vertical-log.vercel.app/api")!
    // TODO(sprint-2): wire local dev override via Info.plist VL_API_BASE_URL
}
