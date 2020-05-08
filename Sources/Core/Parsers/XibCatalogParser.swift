//

import Foundation
import SwiftyXML

private enum XibColor {
    case calibratedWhite(white: Float)
    case calibratedRGB(red: Float, green: Float, blue: Float)

    init?(element: XML) {
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

        if colorSpace == "calibratedRGB" || customColorSpace == "sRGB" || customColorSpace == "displayP3" {
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
            let rgbFactor = (white * 255.0).toHex
            let hex = rgbFactor + rgbFactor + rgbFactor

            return ColorSpec(name: name, value: hex)
        case .calibratedRGB(let red, let green, let blue):
            let rFactor = (red * 255.0).toHex
            let gFactor = (green * 255.0).toHex
            let bFactor = (blue * 255.0).toHex
            let hex = rFactor + gFactor + bFactor
            
            return ColorSpec(name: name, value: hex)
        }
    }
}

public final class XibParser {

    public static func parse(at path: String) -> [ColorSpec] {
        let fileUrl = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: fileUrl)
        let xml = XML(data: data)!

        return self.colorSpecs(from: xml.objects.xml!.children, currentColorSpecs: [])
    }

    private static func colorSpecs(from elements: [XML], currentColorSpecs: [ColorSpec]) -> [ColorSpec] {
        var currentColorSpecs = currentColorSpecs

        currentColorSpecs = elements.reduce(currentColorSpecs) { newColorSpecs, element in
            var newColorSpecs = newColorSpecs

            let xibColor = XibColor(element: element)
            let xibColorSpec = xibColor?.makeColorSpec(name: String(newColorSpecs.count))
            
            newColorSpecs += [xibColorSpec].compactMap { $0 }

            return self.colorSpecs(from: element.children, currentColorSpecs: newColorSpecs)
        }

        return currentColorSpecs
    }

    public static func replace(at path: String, with colorMatches: [ColorSpec]) {
        let fileUrl = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: fileUrl)
        let xml = XML(data: data).require(hint: "Unable to parse XML file. Path: \(path)")

        self.replace(from: xml.objects.xml!.children, index: 0, colorMatches: colorMatches)

        let resources = xml.resources.xml ?? {
            let newResourcesElement = XML(name: "resources")
            xml.addChild(newResourcesElement)

            return newResourcesElement
        }()
        let namedColors = self.namedColors(for: colorMatches, currentResources: resources)
        namedColors.forEach(resources.addChild)

        do {
            let document = [#"<?xml version="1.0" encoding="UTF-8"?>"#, xml.toXMLString()]
                               .joined(separator: "\n")

            try document.write(to: fileUrl, atomically: true, encoding: .nonLossyASCII)
        } catch {
            print("Failed to override XML file at path: \(path)")
            exit(1)
        }
    }

    private static func namedColors(for colorMatches: [ColorSpec], currentResources: XML) ->  [XML] {
        let colorMatches = Array(Set(colorMatches))

        return colorMatches.compactMap { colorMatch in
            guard !currentResources.children.contains(where: { $0.attributes["name"] == colorMatch.name }) else {
                print("Trying to add a color already existing. Name: \(colorMatch.name)")

                return nil
            }

            let newColorElement = XML(name: "color")
            newColorElement.attributes = [
                "red": "\(colorMatch.color.redComponent)",
                "green": "\(colorMatch.color.greenComponent)",
                "blue": "\(colorMatch.color.blueComponent)",
                "alpha": "1", // TODO: Limitation
                "colorSpace": "custom",
                "customColorSpace": "sRGB"
            ]

            let namedColorResource = XML(name: "namedColor")
            namedColorResource.attributes = ["name": colorMatch.name]
            namedColorResource.addChild(newColorElement)

            return namedColorResource
        }
    }

    @discardableResult
    private static func replace(from elements: [XML], index: Int, colorMatches: [ColorSpec]) -> Int {
        var currentIndex = index

        elements.forEach { element in
            if XibColor(element: element) != nil {
                var newElements = element.attributes.filter { $0.key == "key" }
                newElements["name"] = colorMatches[currentIndex].name

                element.attributes = newElements
                currentIndex += 1
            }

            currentIndex = self.replace(from: element.children, index: currentIndex, colorMatches: colorMatches)
        }

        return currentIndex
    }
}
