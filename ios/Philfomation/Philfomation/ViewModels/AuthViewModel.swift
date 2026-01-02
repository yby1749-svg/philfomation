//
//  AuthViewModel.swift
//  Philfomation
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var firebaseUser: FirebaseAuth.User?
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    var isLoggedIn: Bool {
        firebaseUser != nil
    }

    init() {
        firebaseUser = AuthService.shared.currentUser
        setupAuthStateListener()
    }

    deinit {
        if let handle = authStateHandle {
            AuthService.shared.removeAuthStateListener(handle)
        }
    }

    private func setupAuthStateListener() {
        authStateHandle = AuthService.shared.addAuthStateListener { [weak self] user in
            Task { @MainActor in
                self?.firebaseUser = user
                if let userId = user?.uid {
                    await self?.fetchCurrentUser(userId: userId)
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }

    private func fetchCurrentUser(userId: String) async {
        do {
            currentUser = try await FirestoreService.shared.getUser(id: userId)

            // Request push notification permission and save token
            await setupPushNotifications(userId: userId)
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    private func setupPushNotifications(userId: String) async {
        let granted = await PushNotificationService.shared.requestPermission()
        if granted {
            await PushNotificationService.shared.saveFCMToken(userId: userId)
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await AuthService.shared.signIn(email: email, password: password)
            firebaseUser = user
            await fetchCurrentUser(userId: user.uid)
        } catch {
            errorMessage = mapAuthError(error)
        }

        isLoading = false
    }

    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await AuthService.shared.signUp(email: email, password: password, name: name)
            firebaseUser = user
            await fetchCurrentUser(userId: user.uid)
        } catch {
            errorMessage = mapAuthError(error)
        }

        isLoading = false
    }

    func signOut() {
        // Remove FCM token before signing out
        if let userId = firebaseUser?.uid {
            Task {
                await PushNotificationService.shared.removeFCMToken(userId: userId)
            }
        }

        do {
            try AuthService.shared.signOut()
            firebaseUser = nil
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await AuthService.shared.resetPassword(email: email)
        } catch {
            errorMessage = mapAuthError(error)
        }

        isLoading = false
    }

    private func mapAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "비밀번호가 올바르지 않습니다."
        case AuthErrorCode.invalidEmail.rawValue:
            return "유효하지 않은 이메일 형식입니다."
        case AuthErrorCode.userNotFound.rawValue:
            return "등록되지 않은 이메일입니다."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "이미 사용 중인 이메일입니다."
        case AuthErrorCode.weakPassword.rawValue:
            return "비밀번호는 6자리 이상이어야 합니다."
        case AuthErrorCode.networkError.rawValue:
            return "네트워크 연결을 확인해주세요."
        default:
            return error.localizedDescription
        }
    }
}
