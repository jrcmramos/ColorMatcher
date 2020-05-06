//
//  File.swift
//  
//
//  Created by José Ramos on 06.05.20.
//

enum Input {
    case hex(ColorSpec)
    case catalog([ColorSpec])
    case input([ColorSpec])

    var colorSpecs: [ColorSpec] {
        switch self {
        case .hex(let colorSpec): return [colorSpec]
        case .catalog(let colorSpecs): return colorSpecs
        case .input(let colorSpecs): return colorSpecs
        }
    }

    init?(string: String) {
        if string.hasPrefix("0x") {
            let colorSpec = ColorSpec(name: "Hex-Value", value: string)
            self = .hex(colorSpec)

            return
        }

        if string.hasSuffix(".json") {
            let colorSpecs: [ColorSpec] = File.read(from: string)
            self = .input(colorSpecs)

            return
        }

        if string.hasSuffix(".xcassets") {
            let colorSpecs: [ColorSpec] = AssetCatalogParser.parseCatalog(at: string)
            self = .catalog(colorSpecs)

            return
        }

        return nil
    }
}
