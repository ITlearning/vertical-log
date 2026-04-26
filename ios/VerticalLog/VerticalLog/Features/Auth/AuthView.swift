//
//  AuthView.swift
//  VerticalLog
//

import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("vertical-log")
                    .font(.system(size: 32, weight: .bold))
                Text("일상은 세로로")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName]
                },
                onCompletion: handleSignIn
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 32)

            Text("처음이면 새 계정이 만들어집니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 32)
        }
    }

    private func handleSignIn(result: Result<ASAuthorization, Error>) {
        // TODO(sprint-1): wire to POST /auth/apple → JWT → keychain
        // - Validate Apple ID token server-side (web/app/api/auth/apple/route.ts)
        // - Store JWT in iOS Keychain
        // - Update AppSession.isAuthenticated = true
        switch result {
        case .success:
            session.isAuthenticated = true
        case .failure(let error):
            print("[Auth] Sign in failed: \(error)")
        }
    }
}

#Preview {
    AuthView()
        .environment(AppSession())
}
