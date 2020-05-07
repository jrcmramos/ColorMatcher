//
//  File.swift
//  
//
//  Created by José Ramos on 06.05.20.
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

    init?(name: String, assetCatalog: ColorAssetCatalog) {
        guard let firstColor = assetCatalog.colors.first else {
            return nil
        }

        self.name = name
        self.value = [firstColor.color.components.red, firstColor.color.components.green, firstColor.color.components.blue]
                        .map { $0.dropFirst(2) }
                        .joined()
    }

}

final class AssetCatalogParser {

    static func parseCatalog(at path: String) -> [ColorSpec] {
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

            guard let colorSpec = ColorSpec(name: colorName, assetCatalog: colorAssetCatalog) else {
                continue
            }

            colorSpecs.append(colorSpec)
        }

        return colorSpecs
    }

}
