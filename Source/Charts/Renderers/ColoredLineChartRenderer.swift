//
//  ColoredLineChartRenderer.swift
//  Charts
//
//  Created by Kirill Letko on 18.02.23.
//

import Foundation

open class ColoredLineChartRenderer: LineChartRenderer {
    //
    // var chartHeight:CGFloat = 0
    
    private var myXBounds = BarLineScatterCandleBubbleRenderer.XBounds()
    // added to support the commented "Color Section" code below
    // min & maximum visible data geometry coordinate
    private var minVisiblePoint = CGPoint.zero
    private var maxVisiblePoint = CGPoint.zero
    
    override init(dataProvider: LineChartDataProvider, animator: Animator, viewPortHandler: ViewPortHandler) {
        super.init(dataProvider: dataProvider, animator: animator, viewPortHandler: viewPortHandler)
    }
    
    private struct ColorSection {
        // section of graph with specific color
        var min: CGFloat // In data geometry
        var max: CGFloat // In data geometry
        var strokeColor: UIColor
        // var fillColor: UIColor { return strokeColor.withAlphaComponent(0.2) }
        
        static func topBottom(min: Double, max: Double, aboveColor: UIColor, belowColor: UIColor) -> [ColorSection] {
            return [ColorSection(min:  min,
                                 max: CGFloat(max + 1),
                                 strokeColor: aboveColor),
                    ColorSection(min: 0,
                                 max: CGFloat(min),
                                 strokeColor: belowColor)
            ]
        }
    }
    
    @objc open override func drawLinear(context: CGContext, dataSet: LineChartDataSetProtocol) {
        guard let dataProvider = dataProvider else { return }
        
        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        let entryCount = dataSet.entryCount
        let isDrawSteppedEnabled = dataSet.mode == .stepped
        //        let pointsPerEntryPair = isDrawSteppedEnabled ? 4 : 2
        
        let phaseY = animator.phaseY
        
        myXBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)
        
        if dataSet.isDrawFilledEnabled && entryCount > 0
        {
            drawLinearFill(context: context, dataSet: dataSet, trans: trans, bounds: myXBounds)
        }
        
        context.saveGState()
        defer { context.restoreGState() }
        
        // only one color per dataset
        guard dataSet.entryForIndex(myXBounds.min) != nil else {
            return
        }
        
        var firstPoint = true
        
        let path = CGMutablePath()
        for x in stride(from: myXBounds.min, through: myXBounds.range + myXBounds.min, by: 1)
        {
            guard let e1 = dataSet.entryForIndex(x == 0 ? 0 : (x - 1)) else { continue }
            guard let e2 = dataSet.entryForIndex(x) else { continue }
            
            let startPoint =
                CGPoint(
                    x: CGFloat(e1.x),
                    y: CGFloat(e1.y * phaseY))
                .applying(valueToPixelMatrix)
            
            if firstPoint
            {
                path.move(to: startPoint)
                firstPoint = false
            }
            else
            {
                path.addLine(to: startPoint)
            }
            
            if isDrawSteppedEnabled
            {
                let steppedPoint =
                    CGPoint(
                        x: CGFloat(e2.x),
                        y: CGFloat(e1.y * phaseY))
                    .applying(valueToPixelMatrix)
                path.addLine(to: steppedPoint)
            }
            
            let endPoint =
                CGPoint(
                    x: CGFloat(e2.x),
                    y: CGFloat(e2.y * phaseY))
                .applying(valueToPixelMatrix)
            path.addLine(to: endPoint)
        }
        dataSet.fill
        let graphSize = CGSize(width: viewPortHandler.chartWidth, height: viewPortHandler.chartWidth)
        let minValue = dataSet.yValueOfColorChangeBorder != nil ? CGFloat(dataSet.yValueOfColorChangeBorder!.doubleValue) : dataSet.yMin
        for band in ColorSection.topBottom(min: minValue, max: dataSet.yMax, aboveColor: dataSet.fillFormatter?.getFillAboveColor?() ?? .green, belowColor: dataSet.fillFormatter?.getFillBelowColor?() ?? .red) {
            let y0 = max(CGPoint(x: 0, y: band.min).applying(valueToPixelMatrix).y, 0)
            var y1 = min(CGPoint(x: 0, y: band.max).applying(valueToPixelMatrix).y, graphSize.height)
            context.saveGState()
            context.clip(to: CGRect(x: 0, y: y0, width: graphSize.width, height: y1 - y0))
            band.strokeColor.setStroke()
            context.setLineWidth(dataSet.lineWidth)
            context.addPath(path)
            context.strokePath()
            context.restoreGState()
        }
    }
    
    @objc open override func drawHorizontalBezier(context: CGContext, dataSet: LineChartDataSetProtocol) {
        guard let dataProvider = dataProvider else { return }
        
        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        
        let phaseY = animator.phaseY
        myXBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)
        
        // the path for the cubic-spline
        let cubicDrawPath = CGMutablePath()
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        context.saveGState()
        context.beginPath()
        
        if myXBounds.range >= 1 {
            var prev: ChartDataEntry! = dataSet.entryForIndex(myXBounds.min)
            var cur: ChartDataEntry! = prev
            
            if cur == nil { return }
            
            // let the spline start at zero
            cubicDrawPath.move(to: CGPoint(x: CGFloat(cur.x), y: CGFloat(cur.y * phaseY)), transform: valueToPixelMatrix)
            
            for j in myXBounds.dropFirst(1) {
                prev = cur
                cur = dataSet.entryForIndex(j)
                // print("y: (cur.y) when x is (cur.x)")
                // control point for curve
                let cpx = CGFloat(prev.x + (cur.x - prev.x) / 2.0)
                cubicDrawPath.addCurve(
                    to: CGPoint(
                        x: CGFloat(cur.x),
                        y: CGFloat(cur.y * phaseY)),
                    control1: CGPoint(
                        x: cpx,
                        y: CGFloat(prev.y * phaseY)),
                    control2: CGPoint(
                        x: cpx,
                        y: CGFloat(cur.y * phaseY)),
                    transform: valueToPixelMatrix)
            }
            
            let graphSize = CGSize(width: viewPortHandler.chartWidth, height: viewPortHandler.chartWidth)
            for band in ColorSection.topBottom(min: dataSet.yMin, max: dataSet.yMax,  aboveColor: dataSet.fillFormatter?.getFillAboveColor?() ?? .green, belowColor: dataSet.fillFormatter?.getFillBelowColor?() ?? .red) {
                let y0 = max(CGPoint(x: 0, y: band.min).applying(valueToPixelMatrix).y, 0)
                let y1 = min(CGPoint(x: 0, y: band.max).applying(valueToPixelMatrix).y, graphSize.height)
                context.saveGState()    // ; do {
                context.clip(to: CGRect(x: 0, y: y0, width: graphSize.width, height: y1 - y0))
                band.strokeColor.setStroke()
                context.setLineWidth(dataSet.lineWidth)
                context.addPath(cubicDrawPath)
                context.strokePath()
                context.restoreGState()
            }
        }
        context.restoreGState()
    }
    
    open override func drawLinearFill(context: CGContext, dataSet: LineChartDataSetProtocol, trans: Transformer, bounds: XBounds)
    {
        guard let dataProvider = dataProvider else { return }
        
        if let aboveColor = dataSet.fillFormatter?.getFillAboveColor?(), let belowColor = dataSet.fillFormatter?.getFillBelowColor?() {
            let filledAbove = generateFilledPath(
                dataSet: dataSet,
                fillMin: dataSet.fillFormatter?.getFillLinePosition(dataSet: dataSet, dataProvider: dataProvider) ?? 0.0,
                bounds: bounds,
                matrix: trans.valueToPixelMatrix, aboveFillMin: true)

            let filledBelow = generateFilledPath(
                dataSet: dataSet,
                fillMin: dataSet.fillFormatter?.getFillLinePosition(dataSet: dataSet, dataProvider: dataProvider) ?? 0.0,
                bounds: bounds,
                matrix: trans.valueToPixelMatrix, aboveFillMin: false)
            
            if dataSet.fill != nil
            {
                drawFilledPath(context: context, path: filledBelow, fill: dataSet.belowFill!, fillAlpha: dataSet.fillAlpha, transformer: trans)
                drawFilledPath(context: context, path: filledAbove, fill: dataSet.fill!, fillAlpha: dataSet.fillAlpha, transformer: trans)
            }
            else
            {
                drawFilledPath(context: context, path: filledAbove, fillColor: aboveColor, fillAlpha: dataSet.fillAlpha)
                drawFilledPath(context: context, path: filledBelow, fillColor: belowColor, fillAlpha: dataSet.fillAlpha)
            }
        }
    }
    /// Generates the path that is used for filled drawing.
    private func generateFilledPath(dataSet: LineChartDataSetProtocol, fillMin: CGFloat, bounds: XBounds, matrix: CGAffineTransform, aboveFillMin: Bool) -> CGPath
    {
        let phaseY = animator.phaseY
        let isDrawSteppedEnabled = dataSet.mode == .stepped
        let matrix = matrix

        var e: ChartDataEntry!

        let filled = CGMutablePath()

        e = dataSet.entryForIndex(bounds.min)
        if e != nil
        {
            filled.move(to: CGPoint(x: CGFloat(e.x), y: fillMin), transform: matrix)
            filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y * phaseY)), transform: matrix)
        }

        // create a new path
        for x in stride(from: (bounds.min), through: bounds.range + bounds.min, by: 1)
        {
            guard let e = dataSet.entryForIndex(x) else { continue }
           
            if isDrawSteppedEnabled
            {
                guard let ePrev = dataSet.entryForIndex(x-1) else { continue }
                filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(ePrev.y * phaseY)), transform: matrix)
            }
            if aboveFillMin {
                guard let ePrev = dataSet.entryForIndex(x-1), let eNext = dataSet.entryForIndex(x + 1) else {
                    if e.y > fillMin {
                        filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y * phaseY)), transform: matrix)
                    } else {
                        filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(fillMin * phaseY)), transform: matrix)
                    }
                    continue
                }
                
                if e.y > fillMin {
                    filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y * phaseY)), transform: matrix)
                    if eNext.y < fillMin {
                        let xValue = (fillMin - (e.y - (e.x * (eNext.y - e.y)))) / (eNext.y - e.y)
                        filled.addLine(to: CGPoint(x: CGFloat(xValue), y: CGFloat(fillMin * phaseY)), transform: matrix)
                        continue
                    } else if ePrev.y < fillMin {
                        let xValue = (fillMin - (e.y - (e.x * (eNext.y - e.y)))) / (eNext.y - e.y)
                        filled.addLine(to: CGPoint(x: CGFloat(xValue), y: CGFloat(fillMin * phaseY)), transform: matrix)
                        continue
                    }
                } else {
                    if eNext.y > fillMin {
                        let xValue = (fillMin - (e.y - (e.x * (eNext.y - e.y)))) / (eNext.y - e.y)
                        filled.addLine(to: CGPoint(x: CGFloat(xValue), y: CGFloat(fillMin * phaseY)), transform: matrix)
                        continue
                    }
                    print("x: \(e.x), y: \(e.y), (6)")
                    filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(fillMin * phaseY)), transform: matrix)
                }
            } else {
                guard let ePrev = dataSet.entryForIndex(x-1), let eNext = dataSet.entryForIndex(x + 1) else {
                    if e.y < fillMin {
                        filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y * phaseY)), transform: matrix)
                    } else {
                        filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(fillMin * phaseY)), transform: matrix)
                    }
                    continue
                }
                if e.y < fillMin {
                    filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y * phaseY)), transform: matrix)
                    if eNext.y > fillMin {
                        let xValue = (fillMin - (e.y - (e.x * (eNext.y - e.y)))) / (eNext.y - e.y)
                        filled.addLine(to: CGPoint(x: CGFloat(xValue), y: CGFloat(fillMin * phaseY)), transform: matrix)
                        continue
                    } else if ePrev.y > fillMin {
                        let xValue = (fillMin - (e.y - (e.x * (eNext.y - e.y)))) / (eNext.y - e.y)
                        filled.addLine(to: CGPoint(x: CGFloat(xValue), y: CGFloat(fillMin * phaseY)), transform: matrix)
                        continue
                    }
                } else {
                    if eNext.y < fillMin {
                        let xValue = (fillMin - (e.y - (e.x * (eNext.y - e.y)))) / (eNext.y - e.y)
                        filled.addLine(to: CGPoint(x: CGFloat(xValue), y: CGFloat(fillMin * phaseY)), transform: matrix)
                        continue
                    }
                    print("x: \(e.x), y: \(e.y), (6)")
                    filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(fillMin * phaseY)), transform: matrix)
                }
//                }
            }
        }

        // close up
        e = dataSet.entryForIndex(bounds.range + bounds.min)
        if e != nil
        {
            filled.addLine(to: CGPoint(x: CGFloat(e.x), y: fillMin), transform: matrix)
        }
        filled.closeSubpath()

        return filled
    }
    
//    private func generateFilledPath(dataSet: LineChartDataSetProtocol, fillMin: CGFloat, bounds: XBounds, matrix: CGAffineTransform, aboveFillMin: Bool) -> CGPath
//    {
//        let phaseY = animator.phaseY
//        let isDrawSteppedEnabled = dataSet.mode == .stepped
//        let matrix = matrix
//
//        var e: ChartDataEntry!
//
//        let filled = CGMutablePath()
//        e = dataSet.entryForIndex(bounds.min)
//        if e != nil
//        {
//            filled.move(to: CGPoint(x: CGFloat(e.x), y: fillMin), transform: matrix)
//            filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y * phaseY)), transform: matrix)
//        }
//
//        // create a new path
//        for x in stride(from: (bounds.min + 1), through: bounds.range + bounds.min, by: 1)
//        {
//            guard let e = dataSet.entryForIndex(x) else { continue }
//
//            if isDrawSteppedEnabled
//            {
//                guard let ePrev = dataSet.entryForIndex(x-1) else { continue }
//                filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(ePrev.y * phaseY)), transform: matrix)
//            }
//
//            filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y * phaseY)), transform: matrix)
//
//        }
//
//        // close up
//        e = dataSet.entryForIndex(bounds.range + bounds.min)
//        if e != nil
//        {
//            filled.addLine(to: CGPoint(x: CGFloat(e.x), y: fillMin), transform: matrix)
//        }
//        filled.closeSubpath()
//
//        return filled
//    }
//
    
    @objc open override func drawCubicBezier(context: CGContext, dataSet: LineChartDataSetProtocol) {
        guard let dataProvider = dataProvider else { return }
        
        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        
        let phaseY = animator.phaseY
        
        myXBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)
        
        let intensity = dataSet.cubicIntensity
        
        // the path for the cubic-spline
        let cubicPath = CGMutablePath()
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        if myXBounds.range >= 1
        {
            var prevDx: CGFloat = 0.0
            var prevDy: CGFloat = 0.0
            var curDx: CGFloat = 0.0
            var curDy: CGFloat = 0.0
            
            // Take an extra point from the left, and an extra from the right.
            // That's because we need 4 points for a cubic bezier (cubic=4), otherwise we get lines moving and doing weird stuff on the edges of the chart.
            // So in the starting `prev` and `cur`, go -2, -1
            
            let firstIndex = myXBounds.min + 1
            
            var prevPrev: ChartDataEntry! = nil
            var prev: ChartDataEntry! = dataSet.entryForIndex(max(firstIndex - 2, 0))
            var cur: ChartDataEntry! = dataSet.entryForIndex(max(firstIndex - 1, 0))
            var next: ChartDataEntry! = cur
            var nextIndex: Int = -1
            
            if cur == nil { return }
            
            // let the spline start
            cubicPath.move(to: CGPoint(x: CGFloat(cur.x), y: CGFloat(cur.y * phaseY)), transform: valueToPixelMatrix)
            
            for j in myXBounds.dropFirst() {
                prevPrev = prev
                prev = cur
                cur = nextIndex == j ? next : dataSet.entryForIndex(j)
                
                nextIndex = j + 1 < dataSet.entryCount ? j + 1 : j
                next = dataSet.entryForIndex(nextIndex)
                
                if next == nil { break }
                
                prevDx = CGFloat(cur.x - prevPrev.x) * intensity
                prevDy = CGFloat(cur.y - prevPrev.y) * intensity
                curDx = CGFloat(next.x - prev.x) * intensity
                curDy = CGFloat(next.y - prev.y) * intensity
                
                cubicPath.addCurve(
                    to: CGPoint(
                        x: CGFloat(cur.x),
                        y: CGFloat(cur.y) * CGFloat(phaseY)),
                    control1: CGPoint(
                        x: CGFloat(prev.x) + prevDx,
                        y: (CGFloat(prev.y) + prevDy) * CGFloat(phaseY)),
                    control2: CGPoint(
                        x: CGFloat(cur.x) - curDx,
                        y: (CGFloat(cur.y) - curDy) * CGFloat(phaseY)),
                    transform: valueToPixelMatrix)
            }
            
            let graphSize = CGSize(width: viewPortHandler.chartWidth, height: viewPortHandler.chartWidth)
            for band in ColorSection.topBottom(min: dataSet.yMin, max: dataSet.yMax,  aboveColor: dataSet.fillFormatter?.getFillAboveColor?() ?? .green, belowColor: dataSet.fillFormatter?.getFillBelowColor?() ?? .red) {
                let y0 = max(CGPoint(x: 0, y: band.min).applying(valueToPixelMatrix).y, 0)
                let y1 = min(CGPoint(x: 0, y: band.max).applying(valueToPixelMatrix).y, graphSize.height)
                context.saveGState()    // ; do {
                context.clip(to: CGRect(x: 0, y: y0, width: graphSize.width, height: y1 - y0))
                band.strokeColor.setStroke()
                context.setLineWidth(dataSet.lineWidth)
                context.addPath(cubicPath)
                context.strokePath()
                context.restoreGState()
            }
            
        }
        
        context.saveGState()
        defer { context.restoreGState() }
        
        if dataSet.isDrawFilledEnabled
        {
            // Copy this path because we make changes to it
            let fillPath = cubicPath.mutableCopy()
            
            drawCubicFill(context: context, dataSet: dataSet, spline: fillPath!, matrix: valueToPixelMatrix, bounds: myXBounds)
        }
    }
    
    private func drawLine(
        context: CGContext,
        spline: CGMutablePath,
        drawingColor: NSUIColor) {
        context.beginPath()
        context.addPath(spline)
        context.setStrokeColor(drawingColor.cgColor)
        context.strokePath()
    }
    
}
