//
//  CustomRoundedButton.swift
//  AlertSystem
//
//  Created by Joshua Wenata Sunarto on 12/07/24.
//

import Foundation
import SwiftUI

struct CustomRoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
    }
}
