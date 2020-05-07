//
//  File.swift
//  
//
//  Created by José Ramos on 05.05.20.
//

import AppKit
import CoreGraphics

extension NSImage {
    static func makeImage(with color: NSColor,
                          size: CGSize = CGSize(width: 100.0, height: 100.0)) -> NSImage {

        let image = NSImage(size: size)
        image.lockFocus()
        color.drawSwatch(in: .init(origin: .zero, size: .init(width: size.width,
                                                              height: size.height))
        )
        image.unlockFocus()

        return image
    }
}
