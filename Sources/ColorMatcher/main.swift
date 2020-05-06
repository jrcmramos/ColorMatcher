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
    @Option(help: "The path to the base color specifications")
    private var inputColorsPath: String?

    @Option(help: "The value of a color specification. (If no `inputColorsPath` specified)")
    private var hex: String?

    @Argument(help: "The path to the color specifications")
    private var specColorsPath: String

    @Option(help: "The path to the output folder containing the color distance results")
    private var resultsFolder: String?

    @Option(help: "The path to the color specification")
    private var color: String?

    @Flag(name: .long, help: "Show extra logging for debugging purposes")
    private var verbose: Bool

    var inputColors: [ColorSpec] {
        guard let inputColorsPath = self.inputColorsPath else {
            if let colorHex = self.hex {
                return [ColorSpec(name: "Hex-Value", value: colorHex)]
            }

            fatalError("`inputColorsPath` or `hex` should be provided.")
        }

        return File.read(from: inputColorsPath)
    }

    func run() throws {
        let specColors: [ColorSpec] = File.read(from: self.specColorsPath)
        let inputColors = self.inputColors

        let colorMatches: [(original: ColorSpec, match: ColorSpec)] = inputColors.map { inputColor in
            let results: [(ColorSpec, CGFloat)] = specColors.map { ($0, ColorDistance.distance(from: inputColor, to: $0)) }
            let sortedResults = results.sorted { $0.1 < $1.1 }

            print(sortedResults)

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
