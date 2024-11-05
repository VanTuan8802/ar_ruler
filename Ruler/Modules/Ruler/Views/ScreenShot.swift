//
//  ScreenShot.swift
//  Ruler
//
//  Created by Moon Dev on 5/11/24.
//  Copyright © 2024 Tbxark. All rights reserved.
//

import Foundation

extension UIImage {
    convenience init?(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            self.init(cgImage: cgImage)
        } else {
            return nil
        }
    }
}
