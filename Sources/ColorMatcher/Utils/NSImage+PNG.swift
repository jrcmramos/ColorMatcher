//
//  File.swift
//  
//
//  Created by José Ramos on 07.05.20.
//

import AppKit

extension NSImage {

    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }

    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) {
        do {
            try pngData?.write(to: url, options: options)
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }
}

