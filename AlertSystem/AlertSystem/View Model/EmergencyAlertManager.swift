//
//  EmergencyAlertManager.swift
//  Guardi
//
//  Created by Romi Fadhurohman Nabil on 13/07/24.
//

import Foundation

class EmergencyAlertManager: ObservableObject {
    func sendEmail(to email: String, subject: String, message: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "http://35.209.27.3/send-email/") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "subject": subject,
            "message": message
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "Invalid response", code: -1, userInfo: nil)))
                return
            }
            
            completion(.success(()))
        }
        
        task.resume()
    }
}
