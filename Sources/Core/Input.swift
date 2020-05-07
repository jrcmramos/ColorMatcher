//

public enum Input {
    case hex(colorSpecs: ColorSpec)
    case catalog(colorSpecs: [ColorSpec])
    case json(colorSpecs: [ColorSpec])
    case xib(path: String, colorSpecs: [ColorSpec])

    public var colorSpecs: [ColorSpec] {
        switch self {
        case .hex(let colorSpec): return [colorSpec]
        case .catalog(let colorSpecs): return colorSpecs
        case .json(let colorSpecs): return colorSpecs
        case .xib(_, let colorSpecs): return colorSpecs
        }
    }

    public init?(content: String) {
        if content.hasPrefix("0x") {
            let colorSpec = ColorSpec(name: "Hex-Value", value: content)
            self = .hex(colorSpecs: colorSpec)

            return
        }

        if content.hasSuffix(".json") {
            let colorSpecs: [ColorSpec] = File.read(from: content)
            self = .json(colorSpecs: colorSpecs)

            return
        }

        if content.hasSuffix(".xcassets") {
            let colorSpecs: [ColorSpec] = AssetCatalogParser.parse(at: content)
            self = .catalog(colorSpecs: colorSpecs)

            return
        }

        if content.hasSuffix(".xib") {
            let colorSpecs: [ColorSpec] = XibParser.parse(at: content)
            self = .xib(path: content, colorSpecs: colorSpecs)

            return
        }

        return nil
    }
}
