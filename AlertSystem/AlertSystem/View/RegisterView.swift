import SwiftUI
import Firebase

struct RegisterView: View {
    
    @State private var isSignedIn = false
    
    var body: some View {
        VStack {
            Image(systemName: "lock.shield.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("Alert System")
                .font(.title)
                .padding()
            
            Button(action: {
                // Get the top most view controller
                guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
                    print("Failed to get the presenting view controller")
                    return
                }
                
                FirebaseViewModel().signInWithGoogle(presentingViewController: presentingViewController) { result in
                    switch result {
                    case .success(let user):
                        print("User signed in with Firebase: \(user.email ?? "No email")")
                        self.isSignedIn = true // Set state to true upon success
                    case .failure(let error):
                        print("Error during sign-in: \(error.localizedDescription)")
                    }
                }
            }, label: {
                Image("googleLight")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 50)
            })
            .padding()
            
            NavigationLink(
                destination: HomeView(), // Replace with the destination view upon successful sign-in
                isActive: self.$isSignedIn,
                label: {
                    EmptyView() // This can be an empty view, the label itself isn't displayed
                })
                .hidden() // Hide the navigation link, it will navigate automatically when isActive is true
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
