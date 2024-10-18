//
//  CombinedColorChartView.swift
//  Charts
//
//  Created by Kirill Letko on 18.02.23.
//

import Foundation
import CoreGraphics

/// This chart class allows the combination of lines, bars, scatter and candle data all displayed in one chart area.
open class GenericPriceChartView: BarLineChartViewBase, CombinedChartDataProvider
{

    public var cornerRadius: CGFloat = 0.0
    
    /// the fill-formatter used for determining the position of the fill-line
    internal var _fillFormatter: FillFormatter!
    
    /// enum that allows to specify the order in which the different data objects for the combined-chart are drawn
    @objc(GenericPriceChartViewDrawOrder)
    public enum PriceChartDrawOrder: Int
    {
        case bar
        case bubble
        case line
        case candle
        case scatter
    }
    open override func initialize()
    {
        super.initialize()
        
        self.highlighter = CombinedHighlighter(chart: self, barDataProvider: self)
        
        // Old default behaviour
        self.highlightFullBarEnabled = true
        
        _fillFormatter = DefaultFillFormatter()
        renderer = GenericPriceCombinedChartRenderer(chart: self, animator: chartAnimator, viewPortHandler: viewPortHandler)
    }
    
    open override var data: ChartData?
    {
        get
        {
            return super.data
        }
        set
        {
            super.data = newValue
            
            self.highlighter = CombinedHighlighter(chart: self, barDataProvider: self)
            
            (renderer as? GenericPriceCombinedChartRenderer)?.createRenderers()
            renderer?.initBuffers()
        }
    }
    
    @objc open var fillFormatter: FillFormatter
    {
        get
        {
            return _fillFormatter
        }
        set
        {
            _fillFormatter = newValue
            if _fillFormatter == nil
            {
                _fillFormatter = DefaultFillFormatter()
            }
        }
    }
    
    /// - Returns: The Highlight object (contains x-index and DataSet index) of the selected value at the given touch point inside the CombinedChart.
    open override func getHighlightByTouchPoint(_ pt: CGPoint) -> Highlight?
    {
        if data === nil
        {
            Swift.print("Can't select by touch. No data set.")
            return nil
        }
        
        guard let h = self.highlighter?.getHighlight(x: pt.x, y: pt.y)
            else { return nil }
        
        if !isHighlightFullBarEnabled { return h }
        
        // For isHighlightFullBarEnabled, remove stackIndex
        return Highlight(
            x: h.x, y: h.y,
            xPx: h.xPx, yPx: h.yPx,
            dataIndex: h.dataIndex,
            dataSetIndex: h.dataSetIndex,
            stackIndex: -1,
            axis: h.axis)
    }
    
    // MARK: - CombinedChartDataProvider
    
    open var combinedData: CombinedChartData?
    {
        get
        {
            return data as? CombinedChartData
        }
    }
    
    // MARK: - LineChartDataProvider
    
    open var lineData: LineChartData?
    {
        get
        {
            return combinedData?.lineData
        }
    }
    
    // MARK: - BarChartDataProvider
    
    open var barData: BarChartData?
    {
        get
        {
            return combinedData?.barData
        }
    }
    
    // MARK: - ScatterChartDataProvider
    
    open var scatterData: ScatterChartData?
    {
        get
        {
            return combinedData?.scatterData
        }
    }
    
    // MARK: - CandleChartDataProvider
    
    open var candleData: CandleChartData?
    {
        get
        {
            return combinedData?.candleData
        }
    }
    
    // MARK: - BubbleChartDataProvider
    
    open var bubbleData: BubbleChartData?
    {
        get
        {
            return combinedData?.bubbleData
        }
    }
    
    // MARK: - Accessors
    
    /// if set to true, all values are drawn above their bars, instead of below their top
    @objc open var drawValueAboveBarEnabled: Bool
        {
        get { return (renderer as! GenericPriceCombinedChartRenderer).drawValueAboveBarEnabled }
        set { (renderer as! GenericPriceCombinedChartRenderer).drawValueAboveBarEnabled = newValue }
    }
    
    /// if set to true, a grey area is drawn behind each bar that indicates the maximum value
    @objc open var drawBarShadowEnabled: Bool
    {
        get { return (renderer as! GenericPriceCombinedChartRenderer).drawBarShadowEnabled }
        set { (renderer as! GenericPriceCombinedChartRenderer).drawBarShadowEnabled = newValue }
    }
    
    /// `true` if drawing values above bars is enabled, `false` ifnot
    open var isDrawValueAboveBarEnabled: Bool { return (renderer as! GenericPriceCombinedChartRenderer).drawValueAboveBarEnabled }
    
    /// `true` if drawing shadows (maxvalue) for each bar is enabled, `false` ifnot
    open var isDrawBarShadowEnabled: Bool { return (renderer as! GenericPriceCombinedChartRenderer).drawBarShadowEnabled }
    
    /// the order in which the provided data objects should be drawn.
    /// The earlier you place them in the provided array, the further they will be in the background.
    /// e.g. if you provide [DrawOrder.Bar, DrawOrder.Line], the bars will be drawn behind the lines.
    @objc open var drawOrder: [Int]
    {
        get
        {
            return (renderer as! GenericPriceCombinedChartRenderer).drawOrder.map { $0.rawValue }
        }
        set
        {
            (renderer as! GenericPriceCombinedChartRenderer).drawOrder = newValue.map { PriceChartDrawOrder(rawValue: $0)! }
        }
    }
    
    /// Set this to `true` to make the highlight operation full-bar oriented, `false` to make it highlight single values
    @objc open var highlightFullBarEnabled: Bool = false
    
    /// `true` the highlight is be full-bar oriented, `false` ifsingle-value
    open var isHighlightFullBarEnabled: Bool { return highlightFullBarEnabled }
    
    // MARK: - ChartViewBase
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard data != nil, let renderer = renderer else { return }

        let optionalContext = NSUIGraphicsGetCurrentContext()
        guard let context = optionalContext else { return }
        drawMarkers(context: context)
    }
    /// draws all MarkerViews on the highlighted positions
    override func drawMarkers(context: CGContext)
    {
        if let alwaysExistingMarker = alwaysExistingMarker,
           !alwaysHighlighted.isEmpty {
            
            var yCoordinates = {
                var yCoordinatesChanged: [Double] = []
                var currentCoordinates: [Double] = []
                let highlights = alwaysHighlighted
                
                highlights.forEach {
                    let set = combinedData?.getDataSetByHighlight($0)
                    let trans = getTransformer(forAxis: set?.axisDependency ?? .right)
                    let pt = trans.pixelForValues(x: $0.x, y: $0.y)
                    currentCoordinates.append(pt.y)
                }
                if let first = currentCoordinates.first, let second = currentCoordinates.last, currentCoordinates.count == 2 {
                    
                    let maxCoordinate = max(first, second)
                    let minCoordinate = min(first, second)
                    
                    if maxCoordinate - alwaysExistingMarker.size.height < minCoordinate {
                        let newOffset = abs(maxCoordinate - alwaysExistingMarker.size.height - minCoordinate) / 2
                        
                        let firstYCoordinate = first == maxCoordinate ? first + newOffset : first - newOffset
                        let secondYCoordinate = first == maxCoordinate ? second - newOffset : second + newOffset
                        
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
                guard
                    let set = combinedData?.getDataSetByHighlight(highlight),
                    let e = data?.entry(for: highlight)
                else { continue }
                alwaysExistingMarker.refreshContent(entry: e, highlight: highlight)
                let entryIndex = set.entryIndex(entry: e)
                if entryIndex > Int(Double(set.entryCount) * chartAnimator.phaseX)
                {
                    continue
                }
                let coordinates = yCoordinates
                let changedY = coordinates[i]
                let trans = getTransformer(forAxis: set.axisDependency)
                var pt = trans.pixelForValues(x: highlight.x, y: highlight.y)
                pt.y = changedY
                
                if alwaysExistingMarker.size.width > viewPortHandler.chartWidth - viewPortHandler.offsetRight {
                    pt.x = viewPortHandler.chartWidth - viewPortHandler.offsetRight - (alwaysExistingMarker.size.width - viewPortHandler.chartWidth - viewPortHandler.offsetRight)
                } else {
                    pt.x = viewPortHandler.chartWidth - viewPortHandler.offsetRight
                }
                highlight.setDraw(pt: pt)
                
                let pos = getMarkerPosition(highlight: highlight)
                
                if !viewPortHandler.isInBounds(x: pos.x - alwaysExistingMarker.size.width - viewPortHandler.offsetRight, y: pos.y)
                {
                    continue
                }
                alwaysExistingMarker.draw(context: context, point: pos)
            }
        }
        
        
        if let marker = marker,
           isDrawMarkersEnabled && valuesToHighlight() {
            
            for i in highlighted.indices
            {
                let highlight = highlighted[i]
                
                guard
                    let set = combinedData?.getDataSetByHighlight(highlight),
                    let e = data?.entry(for: highlight)
                else { continue }
                
                let entryIndex = set.entryIndex(entry: e)
                if entryIndex > Int(Double(set.entryCount) * chartAnimator.phaseX)
                {
                    continue
                }
                
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
}
 
