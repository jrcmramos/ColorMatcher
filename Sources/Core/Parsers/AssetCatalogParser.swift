//

import Foundation

struct ColorAssetCatalog: Codable {

    struct ColorDefinition: Codable {

        struct Color: Codable {
            struct Components: Codable {
                let red: String
                let green: String
                let blue: String
            }

            let components: Components
        }

        let color: Color
    }

    let colors: [ColorDefinition]
}

fileprivate extension ColorSpec {

    init?(name: String, colorAssetCatalog: ColorAssetCatalog) {
        guard let firstColor = colorAssetCatalog.colors.first?.color else {
            return nil
        }

        self.name = name
        self.value = {
            guard firstColor.components.red.lowercased().hasPrefix("0x") else {
                let rFactor = (Float(firstColor.components.red)! * 255.0).toHex
                let gFactor = (Float(firstColor.components.green)! * 255.0).toHex
                let bFactor = (Float(firstColor.components.blue)! * 255.0).toHex

                return rFactor + gFactor + bFactor
            }

            return [firstColor.components.red,
                    firstColor.components.green,
                    firstColor.components.blue]
                        .map { $0.dropFirst(2) }
                        .joined()
        }()
    }

}

final class AssetCatalogParser {

    static func parse(at path: String) -> [ColorSpec] {
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(atPath: path)
        let decoder = JSONDecoder()

        var colorSpecs: [ColorSpec] = []

        while let element = enumerator?.nextObject() as? String {
            guard element.hasSuffix(".json") else { continue }

            let fileUrl = URL(fileURLWithPath: path + "/" + element)
            let data = try! Data(contentsOf: fileUrl)

            guard let colorAssetCatalog: ColorAssetCatalog = try? decoder.decode(ColorAssetCatalog.self, from: data) else {
                print("Could not parse catalog at path: \(fileUrl)")
                continue
            }

            guard let jsonFileName = fileUrl.pathComponents.first(where: { $0.hasSuffix(".colorset") }),
                  let colorName = jsonFileName.split(separator: ".").map(String.init).first else {
                continue
            }

            guard let colorSpec = ColorSpec(name: colorName, colorAssetCatalog: colorAssetCatalog) else {
                continue
            }

            colorSpecs.append(colorSpec)
        }

        print("Loaded \(colorSpecs.count) colors from catalog")

        return colorSpecs
    }

}
