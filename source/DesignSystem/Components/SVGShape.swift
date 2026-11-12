import SwiftUI

/// Minimal SVG path-data reader (M m L l H h V v C c Z z), so design paths are pasted verbatim
/// from the canvas instead of being transcribed by hand. Not a general SVG parser.
enum SVGPathParser {
    static func path(_ data: String) -> Path {
        var tokens: [Token] = []
        var number = ""
        func flush() {
            if let value = Double(number) { tokens.append(.number(CGFloat(value))) }
            number = ""
        }
        for char in data {
            if char.isLetter {
                flush()
                tokens.append(.command(char))
            } else if char == "-" {
                flush()
                number = "-"
            } else if char == "." {
                if number.contains(".") { flush() }
                number.append(char)
            } else if char.isNumber {
                number.append(char)
            } else {
                flush()
            }
        }
        flush()

        var path = Path()
        var current = CGPoint.zero
        var start = CGPoint.zero
        var index = 0
        var command: Character = " "
        func next() -> CGFloat {
            if index < tokens.count, case .number(let value) = tokens[index] { index += 1; return value }
            return 0
        }
        func hasNumber() -> Bool {
            if index < tokens.count, case .number = tokens[index] { return true }
            return false
        }
        while index < tokens.count {
            if case .command(let c) = tokens[index] { command = c; index += 1 }
            let relative = command.isLowercase
            let base = relative ? current : .zero
            switch command {
            case "M", "m":
                current = CGPoint(x: base.x + next(), y: base.y + next())
                start = current
                path.move(to: current)
                command = relative ? "l" : "L" // further pairs are implicit line-tos
            case "L", "l":
                repeat {
                    let origin = relative ? current : .zero
                    current = CGPoint(x: origin.x + next(), y: origin.y + next())
                    path.addLine(to: current)
                } while hasNumber()
            case "H", "h":
                repeat {
                    current = CGPoint(x: (relative ? current.x : 0) + next(), y: current.y)
                    path.addLine(to: current)
                } while hasNumber()
            case "V", "v":
                repeat {
                    current = CGPoint(x: current.x, y: (relative ? current.y : 0) + next())
                    path.addLine(to: current)
                } while hasNumber()
            case "C", "c":
                repeat {
                    let origin = relative ? current : .zero
                    let c1 = CGPoint(x: origin.x + next(), y: origin.y + next())
                    let c2 = CGPoint(x: origin.x + next(), y: origin.y + next())
                    let end = CGPoint(x: origin.x + next(), y: origin.y + next())
                    path.addCurve(to: end, control1: c1, control2: c2)
                    current = end
                } while hasNumber()
            case "Z", "z":
                path.closeSubpath()
                current = start
                command = " " // data after z needs its own command
            default:
                return path // unsupported command: stop rather than draw garbage
            }
        }
        return path
    }

    private enum Token {
        case command(Character)
        case number(CGFloat)
    }
}

/// Draws prepared SVG path data scaled into the rect: uniform and centred (like `meet`), or stretched
/// (like `preserveAspectRatio="none"`). Parse once into a `static let`, not inside `body`.
struct SVGShape: Shape {
    let source: Path
    let viewBox: CGSize
    var stretch = false

    func path(in rect: CGRect) -> Path {
        guard viewBox.width > 0, viewBox.height > 0 else { return Path() }
        let sx = rect.width / viewBox.width
        let sy = rect.height / viewBox.height
        let scaleX = stretch ? sx : min(sx, sy)
        let scaleY = stretch ? sy : min(sx, sy)
        let originX = rect.midX - viewBox.width * scaleX / 2
        let originY = rect.midY - viewBox.height * scaleY / 2
        let transform = CGAffineTransform(translationX: originX, y: originY).scaledBy(x: scaleX, y: scaleY)
        return source.applying(transform)
    }
}
