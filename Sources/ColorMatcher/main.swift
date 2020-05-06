import ArgumentParser
import Foundation
import AppKit

struct ColorMatcher: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A command line tool to obtain the difference between two colors using the `deltaE` formula",
        subcommands: [Distance.self])

    init() { }
}

struct Distance: ParsableCommand {

    // Input color
    @Argument(help: "Color(s) to find match agains specs. You can provide hex values, path to an Asset catalog or json with `ColorSpec` format")
    private var originalColors: String

    // Specs
    @Argument(help: "Color specifications. You can provide hex values, path to an Asset catalog or json with `ColorSpec` format")
    private var specColors: String

    // Results
    @Option(help: "The path to the output folder containing the color distance results")
    private var resultsFolder: String?

    @Flag(name: .long, help: "Show extra logging for debugging purposes")
    private var verbose: Bool

    func run() throws {
        let originalColorsInput: Input = Input(string: self.originalColors).require(hint: "Invalid original colors input")
        let specColorsInput: Input = Input(string: self.specColors).require(hint: "Invalid spec colors input")

        let originalColors = originalColorsInput.colorSpecs
        let specColors = specColorsInput.colorSpecs

        let colorMatches: [(original: ColorSpec, match: ColorSpec)] = originalColors.map { inputColor in
            let results: [(ColorSpec, CGFloat)] = specColors.map { ($0, ColorDistance.distance(from: inputColor, to: $0)) }
            let sortedResults = results.sorted { $0.1 < $1.1 }

            return (inputColor, sortedResults.first!.0)
        }

        if let resultsFolder = self.resultsFolder {
            self.save(results: colorMatches, into: resultsFolder)
        } else {
            colorMatches.forEach { original, match in
                print("Result for color named `\(original.name)`: Original \(original.value); Match \(match.value)")
            }
        }
    }

    private func save(results: [(original: ColorSpec, match: ColorSpec)], into resultsFolder: String) {
        let saveImage: (NSImage, ColorSpec, String) -> Void = { colorImage, color, filename in
            let url = URL(fileURLWithPath: resultsFolder + "/\(color.name)/\(filename).png")
            colorImage.pngWrite(to: url)
        }

        results.forEach { original, match in
            let originalImage = NSImage.makeImage(with: original.color)
            let matchImage = NSImage.makeImage(with: match.color)

            let colorFolderPath = resultsFolder + "/" + original.name
            File.createFolder(with: colorFolderPath)

            saveImage(originalImage, original, "original")
            saveImage(matchImage, original, "match")
        }
    }
}

ColorMatcher.main()

extension NSImage {

    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }

    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) {
        do {
            try pngData?.write(to: url, options: options)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
