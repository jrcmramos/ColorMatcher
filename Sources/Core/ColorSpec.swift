//

import AppKit

public struct ColorSpec: Codable, Hashable {
    public let name: String
    public let value: String
}

public extension ColorSpec {

    var hex: UInt {
        let valueWithoutPrefix = self.value.lowercased().hasPrefix("0x") ? String(self.value.dropFirst(2)) : self.value

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
