//
//  Line.swift
//  AlertSystem
//
//  Created by Joshua Wenata Sunarto on 12/07/24.
//

import Foundation
import SwiftUI

struct Line: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        return path
    }
}
