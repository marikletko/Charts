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
        
        let yCoordinates: [Double] = {
            var yCoordinatesChanged: [Double] = []
            var currentCoordinates: [Double] = []
            let highlights = alwaysHighlighted
            
            highlights.forEach {
                let set = data?.dataSet(at: $0.dataSetIndex)
                let trans = getTransformer(forAxis: set?.axisDependency ?? .right)
                let pt = trans.pixelForValues(x: $0.x, y: $0.y)
                currentCoordinates.append(pt.y)
            }
            
            let minY = viewPortHandler.contentTop
  
            if let first = currentCoordinates.first, let second = currentCoordinates.last, currentCoordinates.count == 2 {
                
                var maxCoordinate = max(first, second)
                var minCoordinate = min(first, second)

                if maxCoordinate - marker.size.height < minCoordinate {
                    let newOffset = abs(maxCoordinate - marker.size.height - minCoordinate) / 2
                    
                    var firstYCoordinate = first == maxCoordinate ? first + newOffset : first - newOffset
                    var secondYCoordinate = first == maxCoordinate ? second - newOffset : second + newOffset

                    yCoordinatesChanged.append(firstYCoordinate)
                    yCoordinatesChanged.append(secondYCoordinate)
                } else {
                    return currentCoordinates
                }
                
                return yCoordinatesChanged
            } else {
                return currentCoordinates
            }
        }()
        
        for i in alwaysHighlighted.indices
        {
            let highlight = alwaysHighlighted[i]
            let changedY = yCoordinates[i]
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
            
            var pt = trans.pixelForValues(x: highlight.x, y: highlight.y)
            pt.y = changedY
            pt.x = viewPortHandler.contentRect.width// - marker.size.width
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
