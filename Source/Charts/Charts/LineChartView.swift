//
//  LineChartView.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

/// Chart that draws lines, surfaces, circles, ...
open class LineChartView: BarLineChartViewBase, LineChartDataProvider
{
    internal override func initialize()
    {
        super.initialize()
        
        renderer = LineChartRenderer(dataProvider: self, animator: chartAnimator, viewPortHandler: viewPortHandler)
    }
    
    // MARK: - LineChartDataProvider
    
    open var lineData: LineChartData? { return data as? LineChartData }
    
    override func drawMarkers(context: CGContext) {
        super.drawMarkers(context: context)
        
        
        guard
            let marker = alwaysExistingMarker,
            isDrawMarkersEnabled && !alwaysHighlighted.isEmpty
        else { return }
        
        for i in alwaysHighlighted.indices
        {
            let highlight = alwaysHighlighted[i]
            
            guard
                let set = data?.dataSet(at: highlight.dataSetIndex),
                let e = data?.entry(for: highlight)
            else { continue }
            
            let entryIndex = set.entryIndex(entry: e)
            if entryIndex > Int(Double(set.entryCount) * chartAnimator.phaseX)
            {
                continue
            }
    
            let trans = getTransformer(forAxis: set.axisDependency)
            
            let pt = trans.pixelForValues(x: highlight.x, y: highlight.y)
            
            highlight.setDraw(pt: pt)
            
            let pos = getMarkerPosition(highlight: highlight)
            
            
            
            
            // check bounds
            if !viewPortHandler.isInBounds(x: pos.x, y: pos.y)
            {
                continue
            }
            
            // callbacks to update the content
            marker.refreshContent(entry: e, highlight: highlight)
            
            // draw the marker
            marker.draw(context: context, point: pos)
        }
        
        
    }
}
