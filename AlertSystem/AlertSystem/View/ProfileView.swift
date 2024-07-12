import SwiftUI

struct ProfileView: View {
    @State private var userData: [String: String] = [:]
    @State private var emergencyContactEmails: [String] = []

    var body: some View {
        VStack(spacing: 20) {
            List {
                Section(header: Text("Personal Information").foregroundColor(.black)) {
                    NavigationLink(destination: UserDataView()) {
                        HStack {
                            Text("User Data")
                            Spacer()
                            Text(userData.isEmpty ? "Required, Not set" : "Edit")
                        }
                    }
                    NavigationLink(destination: EmergencyView()) {
                        HStack {
                            Text("Emergency Contact")
                            Spacer()
                            Text(emergencyContactEmails.isEmpty ? "Required, Not set" : "Edit")
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .background(Color.clear)
            .padding() // Optional: Add padding around the list
        }
        .padding()
        .background(Color.background) // Set VStack background explicitly to white
        .onAppear {
            loadUserData()
            loadEmergencyContactEmails()
        }
    }
    
    private func loadUserData() {
        if let userData = UserDefaults.standard.dictionary(forKey: "userData") as? [String: String] {
            self.userData = userData
        }
    }

    private func loadEmergencyContactEmails() {
        if let savedContacts = UserDefaults.standard.data(forKey: "EmergencyContacts") {
            let decoder = JSONDecoder()
            if let loadedContacts = try? decoder.decode([EmergencyContact].self, from: savedContacts) {
                emergencyContactEmails = loadedContacts.map { $0.email }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
