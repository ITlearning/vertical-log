//
//  AuthService.swift
//  VerticalLog
//

import AuthenticationServices
import Foundation

struct AuthResponse: Decodable, Sendable {
    struct UserPayload: Decodable, Sendable {
        let id: String
        let displayName: String
    }
    let jwt: String
    let user: UserPayload
}

private struct AppleSignInRequest: Encodable {
    struct FullName: Encodable {
        let givenName: String?
        let familyName: String?
    }
    let identityToken: String
    let authorizationCode: String?
    let fullName: FullName?
}

actor AuthService {
    static let shared = AuthService()

    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    /// Trade an Apple ASAuthorization for our session JWT, store in Keychain,
    /// and configure APIClient to use it. Returns the user payload.
    func signInWithApple(_ authorization: ASAuthorization) async throws -> AuthResponse.UserPayload {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }
        guard let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.missingIdentityToken
        }
        let codeData = credential.authorizationCode
        let code = codeData.flatMap { String(data: $0, encoding: .utf8) }

        let req = AppleSignInRequest(
            identityToken: token,
            authorizationCode: code,
            fullName: credential.fullName.map {
                AppleSignInRequest.FullName(
                    givenName: $0.givenName,
                    familyName: $0.familyName
                )
            }
        )

        let response: AuthResponse = try await api.post("auth/apple", body: req)
        try Keychain.save(response.jwt, for: .sessionToken)
        await api.setJWT(response.jwt)
        return response.user
    }

    /// Restore the session from Keychain on app launch. Returns true if a token
    /// is present (the JWT is not validated locally — the backend will reject it
    /// on the next request if expired, and the UI should sign out).
    func restoreSession() async -> Bool {
        guard let token = Keychain.load(.sessionToken) else { return false }
        await api.setJWT(token)
        return true
    }

    func signOut() async {
        Keychain.delete(.sessionToken)
        await api.setJWT(nil)
    }
}

enum AuthError: Error, LocalizedError {
    case invalidCredential
    case missingIdentityToken

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Sign in with Apple credential 형식이 잘못됐어요."
        case .missingIdentityToken: return "Apple identity token이 비어있어요."
        }
    }
}
