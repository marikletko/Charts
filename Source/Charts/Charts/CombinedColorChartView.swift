//
//  CombinedColorChartView.swift
//  Charts
//
//  Created by Kirill Letko on 18.02.23.
//

import Foundation
import CoreGraphics

open class CombinedColorChartView: CombinedChartView {
    open override func initialize()
    {
        super.initialize()
        
        self.highlighter = CombinedHighlighter(chart: self, barDataProvider: self)
        
        // Old default behaviour
        self.highlightFullBarEnabled = true
        
        _fillFormatter = DefaultFillFormatter()
        renderer = CombinedColorChartRenderer(chart: self, animator: chartAnimator, viewPortHandler: viewPortHandler)
    }
}
