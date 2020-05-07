import ArgumentParser
import Foundation
import Core
import AppKit

struct ColorMatcher: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A command line tool to obtain the difference between two colors using the `deltaE` formula",
        subcommands: [Match.self])

    init() { }
}

struct Match: ParsableCommand {

    // Input color
    @Argument(help: "Color(s) to compare against specs. You can provide a hexadecimal value, asset catalog path, xib file path or a json file with `ColorSpec` format")
    private var originalColors: String

    // Specs
    @Argument(help: "Color specifications. You can provide a hexadecimal value, asset catalog path or a json file with `ColorSpec` format")
    private var specColors: String

    // Results
    @Option(help: "Output folder containg a comparision between the original and spec color.")
    private var resultsFolder: String?

    @Flag(name: .long, help: "Replaces Xib colors with spec colors (if a xib file is provided)")
    private var replaceXibColors: Bool

    func run() throws {
        let originalColorsInput: Input = Input(content: self.originalColors).require(hint: "Invalid original colors input")
        let specColorsInput: Input = Input(content: self.specColors).require(hint: "Invalid spec colors input")
        let originalColors = originalColorsInput.colorSpecs
        let specColors = specColorsInput.colorSpecs

        self.checkCommandLineParameters(originalColors: originalColors, specColors: specColors)
        let colorMatches = self.findMatches(from: originalColors, to: specColors)
        self.presentResults(with: colorMatches, resultsFolder: self.resultsFolder)
        self.replaceXibColorsIfNeeded(originalColorsInput: originalColorsInput, colorMatches: colorMatches.map { $0.match })
    }

    private func checkCommandLineParameters(originalColors: [Core.ColorSpec], specColors: [Core.ColorSpec]) {
        guard !originalColors.isEmpty else {
            print("`originalColors` parameter shouldn´t be empty")
            Foundation.exit(1)
        }

        guard !specColors.isEmpty else {
            print("`specColors` parameter shouldn´t be empty")
            Foundation.exit(1)
        }
    }

    private func findMatches(from originalColors: [Core.ColorSpec], to specColors: [Core.ColorSpec]) ->  [(original: Core.ColorSpec, match: Core.ColorSpec)] {
        return originalColors.map { inputColor in
            let results: [(Core.ColorSpec, CGFloat)] = specColors.map { ($0, ColorDistance.distance(from: inputColor, to: $0)) }
            let sortedResults = results.sorted { $0.1 < $1.1 }
            let bestMatch = (sortedResults.first?.0).require(hint: "specColors` parameter shouldn´t be empty")

            return (inputColor, bestMatch)
        }
    }

    private func presentResults(with colorMatches: [(original: Core.ColorSpec, match: Core.ColorSpec)], resultsFolder: String?) {
        if let resultsFolder = resultsFolder {
            self.save(results: colorMatches, into: resultsFolder)

            return
        }

        colorMatches.forEach { original, match in
            print("Result for color named `\(original.name)`: Original \(original.value); Match \(match.value)")
        }
    }

    private func save(results: [(original: Core.ColorSpec, match: Core.ColorSpec)], into resultsFolder: String) {
        let saveImage: (NSImage, Core.ColorSpec, String) -> Void = { colorImage, color, filename in
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

    private func replaceXibColorsIfNeeded(originalColorsInput: Input, colorMatches: [Core.ColorSpec]) {
        guard self.replaceXibColors, case .xib(let path, _) = originalColorsInput else {
            return
        }

        XibParser.replace(at: path, with: colorMatches)
        // XML element's attributes are parsed as dictionaries, we cannot guarantee the same order as before
        // Using `intool` we can respect Xcode's sorting and formatting
        shell("ibtool", "--upgrade", path, "--write", self.originalColors)
    }
}

ColorMatcher.main()
