//
//  ColorDistance.swift
//  ColorMatcher
//
//  Created by José Ramos on 05.05.20.
//  Copyright © 2020 Vilea. All rights reserved.
//

import Foundation
import AppKit

extension ColorSpec {

    var hex: UInt {
        let valueWithoutPrefix = self.value.hasPrefix("0x") ? String(self.value.dropFirst(2)) : self.value

        guard let hexValue = UInt(valueWithoutPrefix, radix: 16) else {
            print("Invalid Color Spec value.\n\(self)")
            exit(1)
        }

        return hexValue
    }

    func extract(component: ColorComponent) -> UInt {
        return (self.hex >> component.shift) & 0xFF
    }

    var color: NSColor {
        let red = CGFloat(self.extract(component: .r)) / 255.0
        let green = CGFloat(self.extract(component: .g)) / 255.0
        let blue = CGFloat(self.extract(component: .b)) / 255.0

        return NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1.0)
    }
}

enum ColorComponent {
    case r, g, b

    var shift: UInt {
        switch self {
        case .r:
            return 16
        case .g:
            return 8
        case .b:
            return 0
        }
    }
}

final class ColorDistance {

    static func distance(from color1: ColorSpec, to color2: ColorSpec) -> CGFloat {
        let drp2 = Self.distanceByComponent(from: color1, to: color2, component: .r)
        let dgp2 = Self.distanceByComponent(from: color1, to: color2, component: .g)
        let dbp2 = Self.distanceByComponent(from: color1, to: color2, component: .b)

        return sqrt(drp2 + dgp2 + dbp2)
    }

    private static func distanceByComponent(from color1: ColorSpec, to color2: ColorSpec, component: ColorComponent) -> CGFloat {
        return pow(CGFloat(color1.extract(component: component)) - CGFloat(color2.extract(component: component)), 2)
    }
}
