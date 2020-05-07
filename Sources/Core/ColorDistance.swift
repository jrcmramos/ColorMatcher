//

import Foundation
import AppKit

public enum ColorComponent {
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

public final class ColorDistance {

    public static func distance(from color1: ColorSpec, to color2: ColorSpec) -> CGFloat {
        return color1.color.CIE94(compare: color2.color)
    }

    private static func distanceByComponent(from color1: ColorSpec, to color2: ColorSpec, component: ColorComponent) -> CGFloat {
        return pow(CGFloat(color1.extract(component: component)) - CGFloat(color2.extract(component: component)), 2)
    }
}
