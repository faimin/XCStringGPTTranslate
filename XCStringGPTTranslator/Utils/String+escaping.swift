import Foundation

public extension String {
    func unescape() -> String {
        let input = self
        var result = ""
        var i = input.startIndex

        while i < input.endIndex {
            let char = input[i]
            if char == "\\" {
                let nextIndex = input.index(after: i)
                if nextIndex < input.endIndex {
                    let nextChar = input[nextIndex]

                    switch nextChar {
                    case "b": result.append("\u{0008}") // backspace
                    case "t": result.append("\t") // tab
                    case "n": result.append("\n") // newline
                    case "f": result.append("\u{000C}") // form feed
                    case "r": result.append("\r") // carriage return
                    case "\"": result.append("\"") // double quote
                    case "'": result.append("'") // single quote
                    case "\\": result.append("\\") // backslash
                    case "u":
                        let unicodeStartIndex = input.index(i, offsetBy: 2)
                        let unicodeEndIndex = input.index(unicodeStartIndex, offsetBy: 4)
                        let unicodeHex = input[unicodeStartIndex ..< unicodeEndIndex]

                        if let unicodeValue = UInt16(unicodeHex, radix: 16),
                           let unicodeScalar = UnicodeScalar(unicodeValue) {
                            result.append(String(unicodeScalar))
                            i = unicodeEndIndex
                        } else {
                            result.append("\\u")
                        }

                        continue
                    default: result.append("\\")
                    }

                    i = nextIndex
                } else {
                    result.append("\\")
                }
            } else {
                result.append(char)
            }
            i = input.index(after: i)
        }
        return result
    }
}
