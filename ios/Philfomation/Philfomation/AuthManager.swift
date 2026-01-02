//
//  AuthManager.swift
//  Philfomation
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var isLoggedIn: Bool {
        user != nil
    }

    init() {
        user = Auth.auth().currentUser
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
            }
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            user = result.user
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            user = result.user
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
