//
//  MeasurementMode.swift
//  Ruler
//
//  Created by Moon Dev on 5/11/24.
//  Copyright © 2024 Tbxark. All rights reserved.
//

import Foundation

enum MeasurementMode {
    case length
    case area
    func toAttrStr() -> NSAttributedString {
        let str = self == .area ? Localization.startArea.toString() : Localization.startLength.toString()
        return NSAttributedString(string: str, attributes: [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 20),
                                                             NSAttributedStringKey.foregroundColor: UIColor.black])
    }
}
