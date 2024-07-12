import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn

class FirebaseViewModel: ObservableObject {
    @Published var isSignedIn = false
        
    init() {
        // Check initial authentication state
        checkAuthentication()
    }
    
    func checkAuthentication() {
        Auth.auth().addStateDidChangeListener { (auth, user) in
            self.isSignedIn = user != nil
        }
    }
    
    func firebaseAuthConfig() {
        FirebaseApp.configure()
    }
    
    func signInWithGoogle(presentingViewController: UIViewController, completion: @escaping (Result<User, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "SignInError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get client ID"])))
            return
        }
        
        // Create Google Sign-In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign-in flow!
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(NSError(domain: "SignInError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve user, idToken, or accessToken"])))
                return
            }
            
            let accessToken = user.accessToken.tokenString
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // Authenticate with Firebase using the Google credentials
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let user = authResult?.user else {
                    completion(.failure(NSError(domain: "SignInError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Firebase sign-in succeeded, but user object is nil"])))
                    return
                }
                
                completion(.success(user))
            }
        }
    }
    
    func logout() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}
