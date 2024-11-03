import SwiftUI
import FirebaseAuth
import AuthenticationServices
import CryptoKit

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: ThemeGradient.primary),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: ThemeMetrics.Padding.extraLarge) {
                    // App logo and title
                    VStack(spacing: ThemeMetrics.Padding.medium) {
                        Image(systemName: "music.note.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(ThemeColor.text.color)
                            .shadow(radius: ThemeShadow.large.radius)
                        
                        Text("iSongs")
                            .font(ThemeFont.title(.extraLarge))
                            .foregroundColor(ThemeColor.text.color)
                            .shadow(radius: ThemeShadow.medium.radius)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Authentication form
                    VStack(spacing: ThemeMetrics.Padding.large) {
                        // Email/Password fields
                        VStack(spacing: ThemeMetrics.Padding.medium) {
                            AuthTextField(
                                text: $viewModel.email,
                                placeholder: "Email",
                                icon: "envelope.fill"
                            )
                            
                            AuthSecureField(
                                text: $viewModel.password,
                                placeholder: "Password",
                                icon: "lock.fill"
                            )
                            
                            // Sign In/Up Button
                            Button(action: {
                                viewModel.handleEmailAuth { success in
                                    if success {
                                        isAuthenticated = true
                                    }
                                }
                            }) {
                                ZStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    } else {
                                        Text(viewModel.isLogin ? "Sign In" : "Sign Up")
                                            .font(ThemeFont.headline())
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                            }
                            .themeButton()
                            .disabled(viewModel.isLoading)
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(ThemeColor.divider.color)
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(ThemeFont.caption())
                                .foregroundColor(ThemeColor.secondaryText.color)
                            
                            Rectangle()
                                .fill(ThemeColor.divider.color)
                                .frame(height: 1)
                        }
                        
                        // Social Sign In Buttons
                        VStack(spacing: ThemeMetrics.Padding.medium) {
                            // Apple Sign In
                            SignInWithAppleButton(
                                onRequest: { request in
                                    viewModel.handleAppleSignInRequest(request)
                                },
                                onCompletion: { result in
                                    viewModel.handleAppleSignInCompletion(result) { success in
                                        if success {
                                            isAuthenticated = true
                                        }
                                    }
                                }
                            )
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 50)
                            .cornerRadius(ThemeMetrics.CornerRadius.medium)
                            
                            // Google Sign In Button
                            Button(action: {
                                viewModel.handleGoogleSignIn { success in
                                    if success {
                                        isAuthenticated = true
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "g.circle.fill")
                                        .font(.title2)
                                    Text("Sign in with Google")
                                        .font(ThemeFont.headline())
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                            }
                            .themeButton(style: .secondary)
                        }
                    }
                    .padding(.horizontal, ThemeMetrics.Padding.extraLarge)
                    
                    // Toggle between Sign In/Up
                    Button(action: {
                        withAnimation(ThemeAnimation.standard) {
                            viewModel.isLogin.toggle()
                        }
                    }) {
                        Text(viewModel.isLogin ? "Don't have an account? Sign Up" : "Already have an account? Sign In")
                            .font(ThemeFont.body())
                            .foregroundColor(ThemeColor.text.color.opacity(0.9))
                    }
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct AuthTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ThemeColor.secondaryText.color)
                .frame(width: ThemeMetrics.IconSize.medium)
            
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundColor(ThemeColor.text.color)
        }
        .padding()
        .background(ThemeColor.text.color.opacity(0.1))
        .cornerRadius(ThemeMetrics.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: ThemeMetrics.CornerRadius.medium)
                .stroke(ThemeColor.text.color.opacity(0.1), lineWidth: 1)
        )
    }
}

struct AuthSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ThemeColor.secondaryText.color)
                .frame(width: ThemeMetrics.IconSize.medium)
            
            SecureField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundColor(ThemeColor.text.color)
        }
        .padding()
        .background(ThemeColor.text.color.opacity(0.1))
        .cornerRadius(ThemeMetrics.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: ThemeMetrics.CornerRadius.medium)
                .stroke(ThemeColor.text.color.opacity(0.1), lineWidth: 1)
        )
    }
}

class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLogin = true
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage = ""
    
    private var currentNonce: String?
    
    func handleEmailAuth(completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        let authMethod = isLogin ? Auth.auth().signIn : Auth.auth().createUser
        
        authMethod(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.showingError = true
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>, completion: @escaping (Bool) -> Void) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Apple Sign In failed"
                showingError = true
                completion(false)
                return
            }
            
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )
            
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.showingError = true
                    completion(false)
                } else {
                    completion(true)
                }
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
            completion(false)
        }
    }
    
    func handleGoogleSignIn(completion: @escaping (Bool) -> Void) {
        // Implement Google Sign In
        completion(false)
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

#Preview {
    AuthenticationView(isAuthenticated: .constant(false))
}
