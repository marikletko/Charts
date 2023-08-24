//
//  File.swift
//  
//
//  Created by Kirill Letko on 24.08.23.
//

import Foundation
import CoreGraphics

open class DefaultLineMarkerView: MarkerView {
    required public init(color: NSUIColor, frame: CGRect) {
        super.init(frame: frame)
        let value = frame.height / 2
        self.offset = .init(x: -value, y: -value)
        self.layer.cornerRadius = value
        self.backgroundColor = color
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class ColoredLineMarkerView: MarkerView {
    open var positiveColor: NSUIColor
    open var negativeColor: NSUIColor
    open var value: Double
    
    required public init(positiveColor: NSUIColor, negativeColor: NSUIColor, value: Double, frame: CGRect) {
        self.value = value
        self.negativeColor = negativeColor
        self.positiveColor = positiveColor
        super.init(frame: frame)
        let value = frame.height / 2
        self.offset = .init(x: -value, y: -value)
        self.layer.cornerRadius = value
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        if let data = entry as? CandleChartDataEntry {
            if data.close > data.open {
                self.backgroundColor = positiveColor
            } else if data.close < data.open {
                self.backgroundColor = negativeColor
            } else {
                self.backgroundColor = .darkGray
            }
            return
        }
        if highlight.y > value {
            self.backgroundColor = positiveColor
        } else if highlight.y < value {
            self.backgroundColor = negativeColor
        } else {
            self.backgroundColor = .darkGray
        }
    }
}
