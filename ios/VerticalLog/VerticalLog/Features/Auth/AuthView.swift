//
//  AuthView.swift
//  VerticalLog
//

import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @Environment(AppSession.self) private var session

    @State private var isLoading = false
    @State private var errorMessage: String?

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
            .disabled(isLoading)
            .opacity(isLoading ? 0.5 : 1.0)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Text("처음이면 새 계정이 만들어집니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isLoading {
                ProgressView().padding(.top, 4)
            }

            Spacer().frame(height: 16)
        }
        .padding(.bottom, 32)
    }

    private func handleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            isLoading = true
            errorMessage = nil
            Task {
                do {
                    let user = try await AuthService.shared.signInWithApple(authorization)
                    session.userID = user.id
                    session.displayName = user.displayName
                    session.isAuthenticated = true
                    isLoading = false
                } catch {
                    isLoading = false
                    errorMessage = (error as? LocalizedError)?.errorDescription
                        ?? "로그인에 실패했어요. 잠시 후 다시 시도해주세요."
                    print("[Auth] sign in failed: \(error)")
                }
            }
        case .failure(let error):
            errorMessage = "로그인이 취소됐거나 실패했어요."
            print("[Auth] Sign in failed: \(error)")
        }
    }
}

#Preview {
    AuthView()
        .environment(AppSession())
}
