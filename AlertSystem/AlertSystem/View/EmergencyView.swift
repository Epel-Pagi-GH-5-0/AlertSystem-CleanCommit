import SwiftUI

struct EmergencyContact: Identifiable, Codable {
    var id = UUID()
    var name: String = ""
    var email: String = ""
}

struct EmergencyView: View {
    @State private var contacts: [EmergencyContact] = [EmergencyContact(), EmergencyContact()]
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    ForEach(contacts.indices, id: \.self) { index in
                        Section(header: Text("Person \(index + 1)")) {
                            TextField("Name", text: $contacts[index].name)
                            TextField("Email", text: $contacts[index].email)
                        }
                    }
                    Button(action: {
                        contacts.append(EmergencyContact())
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add emergency contact")
                        }
                    }
                }
                .navigationBarTitle("Emergency Contact")
                
                Button(action: {
                    saveContacts()
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
        }
        .onAppear(perform: loadContacts)
    }
    
    func saveContacts() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(contacts) {
            UserDefaults.standard.set(encoded, forKey: "EmergencyContacts")
        }
    }
    
    func loadContacts() {
        if let savedContacts = UserDefaults.standard.data(forKey: "EmergencyContacts") {
            let decoder = JSONDecoder()
            if let loadedContacts = try? decoder.decode([EmergencyContact].self, from: savedContacts) {
                contacts = loadedContacts
            }
        }
    }
}

struct EmergencyView_Previews: PreviewProvider {
    static var previews: some View {
        EmergencyView()
    }
}
