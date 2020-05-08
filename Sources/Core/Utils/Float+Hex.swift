//

import Foundation

extension Float {

    var toHex: String {
        return String(format:"%02X", Int(self))
    }
}
