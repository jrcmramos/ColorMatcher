//
//  File.swift
//  
//
//  Created by José Ramos on 06.05.20.
//

import Foundation
import SwiftyXMLParser

private enum XibColor {
    case calibratedWhite(white: Float)
    case calibratedRGB(red: Float, green: Float, blue: Float)

    init?(element: XML.Element) {
        guard element.name == "color" else {
            return nil
        }

        let colorSpace = element.attributes["colorSpace"]
        let customColorSpace = element.attributes["customColorSpace"]
        let colorSpaceDescriptor = customColorSpace ?? colorSpace ?? "[EMPTY]"

        if colorSpace == "calibratedWhite" || customColorSpace == "genericGamma22GrayColorSpace" {
            guard let white = element.attributes["white"].flatMap(Float.init) else {
                print("Didn't find white for colorSpace: \(colorSpaceDescriptor)")
                return nil
            }

            self = .calibratedWhite(white: white)

            return
        }

        if colorSpace == "calibratedRGB" || customColorSpace == "sRGB" {
            guard let red = element.attributes["red"].flatMap(Float.init),
                 let green = element.attributes["green"].flatMap(Float.init),
                 let blue = element.attributes["blue"].flatMap(Float.init) else {
               print("Didn't find all RGB elements for colorSpace: \(colorSpaceDescriptor)")
               return nil
           }

            self = .calibratedRGB(red: red, green: green, blue: blue)

            return
        }

        print("Unable to find color scheme for colorSpace: \(colorSpaceDescriptor)")

        return nil
    }

    func makeColorSpec(name: String) -> ColorSpec {
        switch self {
        case .calibratedWhite(let white):
            let rgbFactor = String(format:"%02X", Int(white * 255.0))
            let hex = "0x" + rgbFactor + rgbFactor + rgbFactor

            return ColorSpec(name: name, value: hex)
        case .calibratedRGB(let red, let green, let blue):
            let rFactor = String(format:"%02X", Int(red * 255.0))
            let gFactor = String(format:"%02X", Int(green * 255.0))
            let bFactor = String(format:"%02X", Int(blue * 255.0))

            let hex = "0x" + rFactor + gFactor + bFactor

            return ColorSpec(name: name, value: hex)
        }
    }

}

final class XibCatalogParser {

    static func parseXib(at path: String) -> [ColorSpec] {
        let fileUrl = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: fileUrl)

        let xml = XML.parse(data)

        return self.colorSpecs(from: xml.all ?? [], currentColorSpecs: [])
    }

    private static func colorSpecs(from elements: [XML.Element], currentColorSpecs: [ColorSpec]) -> [ColorSpec] {
        var currentColorSpecs = currentColorSpecs

        currentColorSpecs = elements.reduce(currentColorSpecs) { newColorSpecs, element in
            var newColorSpecs = newColorSpecs

            let xibColor = XibColor(element: element)
            let xibColorSpec = xibColor?.makeColorSpec(name: String(newColorSpecs.count))
            
            newColorSpecs += [xibColorSpec].compactMap { $0 }

            return self.colorSpecs(from: element.childElements, currentColorSpecs: newColorSpecs)
        }

        return currentColorSpecs
    }
}

