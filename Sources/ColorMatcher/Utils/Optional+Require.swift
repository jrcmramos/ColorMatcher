//

import Foundation

public extension Optional {

    func require(hint hintExpression: @autoclosure () -> String? = nil,
                 file: StaticString = #file,
                 line: UInt = #line) -> Wrapped {
        guard let unwrapped = self else {
            var message = "Required value was nil in \(file), at line \(line)"

            if let hint = hintExpression() {
                message.append(". Debugging hint: \(hint)")
            }

            #if !os(Linux)
            let exception = NSException(
                name: .invalidArgumentException,
                reason: message,
                userInfo: nil
            )

            exception.raise()
            #endif

            preconditionFailure(message)
        }

        return unwrapped
    }

    func require(orThrowWithMessage message: String) throws -> Wrapped {
        guard let unwrapped = self else {
            throw NSError(domain: message, code: -1, userInfo: nil)
        }

        return unwrapped
    }
}
