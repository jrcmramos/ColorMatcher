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

        print("Skipping color scheme with colorSpace: \(colorSpaceDescriptor)")

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

    static func replaceXib(at path: String, with colorMatches: [ColorSpec]) {
        let fileUrl = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: fileUrl)
        let xml = XML.parse(data, trimming: .whitespacesAndNewlines)
        let allElements = xml.all ?? []

        self.replace(from: allElements, index: 0, colorMatches: colorMatches)

        let resources = xml[0].document.resources.element ?? {
            let newResourcesElement = XML.Element(name: "resources")
            allElements[0].childElements[0].childElements += [newResourcesElement]

            return newResourcesElement
        }()
        let namedColors1 = namedColors(for: colorMatches, currentResources: resources)
        resources.childElements += namedColors1

        // allElements[0] -> Root node
        // allElements[0].childElements[0] -> Document node

        do {
            let document = try XML.document(.init(allElements))

            try document.write(to: fileUrl, atomically: true, encoding: .utf8)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
    }

    private static func namedColors(for colorMatches: [ColorSpec], currentResources: XML.Element) ->  [XML.Element] {
        let colorMatches = Array(Set(colorMatches))

        return colorMatches.compactMap { colorMatch in
            guard !currentResources.childElements.contains(where: { $0.attributes["name"] == colorMatch.name }) else {
                print("Trying to add a color already existing. Name: \(colorMatch.name)")

                return nil
            }

            let newColorElement = XML.Element(name: "color")
            newColorElement.attributes = [
                "red": "\(colorMatch.color.redComponent)",
                "green": "\(colorMatch.color.greenComponent)",
                "blue": "\(colorMatch.color.blueComponent)",
                "alpha": "1",
                "colorSpace": "custom",
                "customColorSpace": "sRGB"
            ]

            let namedColorResource = XML.Element(name: "namedColor")
            namedColorResource.attributes = ["name": colorMatch.name]
            namedColorResource.childElements = [newColorElement]

            return namedColorResource
        }
    }

    @discardableResult
    private static func replace(from elements: [XML.Element], index: Int, colorMatches: [ColorSpec]) -> Int {
        var currentIndex = index

        elements.forEach { element in
            if XibColor(element: element) != nil {
                var newElements = element.attributes.filter { $0.key == "key" }
                newElements["name"] = colorMatches[currentIndex].name

                element.attributes = newElements
                currentIndex += 1
            }

            currentIndex = self.replace(from: element.childElements, index: currentIndex, colorMatches: colorMatches)
        }

        return currentIndex
    }
}
