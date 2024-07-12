import SwiftUI
import UIKit

struct UserDataView: View {
    // State variables to store user input
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var gender = Gender.male // Default selection
    @State private var selectedImage: UIImage? = nil // For storing selected photo
    @State private var showImagePicker = false

    // Gender options
    enum Gender: String, CaseIterable {
        case male = "Male"
        case female = "Female"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Personal Information")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.bottom, 70)
            
            // Full Name TextField
            Text("Full Name")
                .font(.headline)
            
            TextField("Full Name", text: $fullName)
                .textFieldStyle(CustomRoundedTextFieldStyle())
            
            // Email TextField
            Text("Email")
                .font(.headline)
            
            TextField("Email", text: $email)
                .textFieldStyle(CustomRoundedTextFieldStyle())
                .keyboardType(.emailAddress)
            
            // Phone TextField
            Text("Phone")
                .font(.headline)
            
            TextField("Phone", text: $phone)
                .textFieldStyle(CustomRoundedTextFieldStyle())
                .keyboardType(.phonePad)
            
            Text("Gender")
                .font(.headline)
            
            HStack {
                ForEach(Gender.allCases, id: \.self) { option in
                    RadioButtonField(text: option.rawValue, isSelected: option == gender) {
                        gender = option
                    }
                    .background(option == gender ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(option == gender ? Color.blue : Color.gray, lineWidth: 1)
                    )
                }
            }
            .padding()
    
            Spacer() // Center the following elements
            
            // Submit Button
            HStack {
                Spacer()
                Button(action: saveUserData) {
                    Text("Submit")
                        .padding(.horizontal, 120)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, isPresented: $showImagePicker)
        }
        .onAppear(perform: loadUserData) // Load user data when view appears
    }
    
    // Function to save user data to UserDefaults
    private func saveUserData() {
        let userData = [
            "fullName": fullName,
            "email": email,
            "phone": phone,
            "gender": gender.rawValue
        ]
        
        UserDefaults.standard.set(userData, forKey: "userData")
    }
    
    // Function to load user data from UserDefaults
    private func loadUserData() {
        if let userData = UserDefaults.standard.dictionary(forKey: "userData") as? [String: String] {
            fullName = userData["fullName"] ?? ""
            email = userData["email"] ?? ""
            phone = userData["phone"] ?? ""
            if let genderRawValue = userData["gender"], let savedGender = Gender(rawValue: genderRawValue) {
                gender = savedGender
            }
        }
    }
}

struct RadioButtonField: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .foregroundColor(isSelected ? .blue : .black)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 1)
            )
        }
    }
}

#Preview {
    UserDataView()
}
