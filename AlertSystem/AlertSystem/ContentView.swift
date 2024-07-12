import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = FirebaseViewModel()
    
    var body: some View {
        NavigationView {
            if viewModel.isSignedIn {
                HomeView()
            } else {
                RegisterView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
