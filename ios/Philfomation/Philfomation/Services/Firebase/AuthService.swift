//
//  AuthService.swift
//  Philfomation
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    private init() {}

    var currentUser: FirebaseAuth.User? {
        auth.currentUser
    }

    var currentUserId: String? {
        auth.currentUser?.uid
    }

    var isLoggedIn: Bool {
        currentUser != nil
    }

    func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
        let result = try await auth.signIn(withEmail: email, password: password)
        return result.user
    }

    func signUp(email: String, password: String, name: String) async throws -> FirebaseAuth.User {
        let result = try await auth.createUser(withEmail: email, password: password)
        let user = result.user

        // Create user document in Firestore
        let appUser = AppUser(
            id: user.uid,
            name: name,
            email: email,
            userType: .customer
        )

        try await db.collection("users").document(user.uid).setData(from: appUser)

        return user
    }

    func signOut() throws {
        try auth.signOut()
    }

    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func updateDisplayName(_ name: String) async throws {
        guard let user = currentUser else { return }
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
    }

    func updatePhotoURL(_ url: URL) async throws {
        guard let user = currentUser else { return }
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.photoURL = url
        try await changeRequest.commitChanges()
    }

    func addAuthStateListener(_ listener: @escaping (FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle {
        auth.addStateDidChangeListener { _, user in
            listener(user)
        }
    }

    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }
}
