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

    @Flag(name: .long, help: "Replaces Xib colors with spec colors")
    private var replaceXibColors: Bool

    func run() throws {
        let originalColorsInput: Input = Input(string: self.originalColors).require(hint: "Invalid original colors input")
        let specColorsInput: Input = Input(string: self.specColors).require(hint: "Invalid spec colors input")
        let originalColors = originalColorsInput.colorSpecs
        let specColors = specColorsInput.colorSpecs

        self.checkCommandLineParameters(originalColors: originalColors, specColors: specColors)
        let colorMatches = self.findMatches(originalColors: originalColors, specColors: specColors)
        self.presentResults(colorMatches: colorMatches, resultsFolder: self.resultsFolder)
        self.replaceXibColorsIfNeeded(originalColorsInput: originalColorsInput, colorMatches: colorMatches.map { $0.match })
    }

    private func checkCommandLineParameters(originalColors: [ColorSpec], specColors: [ColorSpec]) {
        guard !originalColors.isEmpty else {
            print("`originalColors` parameter shouldn´t be empty")
            Foundation.exit(1)
        }

        guard !specColors.isEmpty else {
            print("`specColors` parameter shouldn´t be empty")
            Foundation.exit(1)
        }
    }

    private func findMatches(originalColors: [ColorSpec], specColors: [ColorSpec]) ->  [(original: ColorSpec, match: ColorSpec)] {
        return originalColors.map { inputColor in
            let results: [(ColorSpec, CGFloat)] = specColors.map { ($0, ColorDistance.distance(from: inputColor, to: $0)) }
            let sortedResults = results.sorted { $0.1 < $1.1 }
            let bestMatch = (sortedResults.first?.0) ?? specColors[0]

            return (inputColor, bestMatch)
        }
    }

    private func presentResults(colorMatches: [(original: ColorSpec, match: ColorSpec)], resultsFolder: String?) {
        if let resultsFolder = resultsFolder {
            self.save(results: colorMatches, into: resultsFolder)

            return
        }

        colorMatches.forEach { original, match in
            print("Result for color named `\(original.name)`: Original \(original.value); Match \(match.value)")
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

    private func replaceXibColorsIfNeeded(originalColorsInput: Input, colorMatches: [ColorSpec]) {
        guard self.replaceXibColors, case .xib = originalColorsInput else {
            return
        }

        XibCatalogParser.replaceXib(at: self.originalColors, with: colorMatches)
        // XML element's attributes are parsed as dictionaries, we cannot guarantee the same order as before
        // Using `intool` we can respect Xcode's sorting and formatting
        shell("ibtool", "--upgrade", self.originalColors, "--write", self.originalColors)
    }
}

ColorMatcher.main()
