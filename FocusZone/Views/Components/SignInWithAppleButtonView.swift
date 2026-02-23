//
//  SignInWithAppleButtonView.swift
//  FocusZone
//
//  SwiftUI wrapper for ASAuthorizationAppleIDButton.
//

import SwiftUI
import AuthenticationServices

struct SignInWithAppleButtonView: View {
    var action: () -> Void

    var body: some View {
        SignInWithAppleButtonRepresentable(action: action)
            .frame(height: 50)
    }
}

private struct SignInWithAppleButtonRepresentable: UIViewRepresentable {
    var action: () -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.cornerRadius = 12
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func tapped() {
            action()
        }
    }
}
