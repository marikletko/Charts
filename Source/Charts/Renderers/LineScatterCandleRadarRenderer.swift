//
//  LineScatterCandleRadarRenderer.swift
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

@objc(LineScatterCandleRadarChartRenderer)
open class LineScatterCandleRadarRenderer: BarLineScatterCandleBubbleRenderer
{
    public override init(animator: Animator, viewPortHandler: ViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
    }
    
    /// Draws vertical & horizontal highlight-lines if enabled.
    /// :param: context
    /// :param: points
    /// :param: horizontal
    /// :param: vertical
    @objc open func drawHighlightLines(context: CGContext, point: CGPoint, set: LineScatterCandleRadarChartDataSetProtocol)
    {
        
        // draw vertical highlight lines
        if set.isVerticalHighlightIndicatorEnabled
        {
            context.beginPath()
            context.move(to: CGPoint(x: point.x, y: viewPortHandler.contentTop))
            context.addLine(to: CGPoint(x: point.x, y: viewPortHandler.contentBottom))
            context.strokePath()
        }
        
        // draw horizontal highlight lines
        if set.isHorizontalHighlightIndicatorEnabled
        {
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: point.y))
            context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: point.y))
            context.strokePath()
        }
    }
    
    @objc open func drawBackgroundFiller(context: CGContext, dataProvider: BarLineScatterCandleBubbleChartDataProvider?, dataSet: any LineScatterCandleRadarChartDataSetProtocol) {
        if let backColor = dataSet.backgroundColor, let trans = dataProvider?.getTransformer(forAxis: .right), let range = dataSet.backgroundFilledXRange, range.count == 2 {
            for i in 0..<1 {
                var _dataSetShadowRectBuffer: CGRect = CGRect()
                
                var positionX = CGPoint.zero
                positionX = .init(x: range[i], y: 0)
                trans.pointValueToPixel(&positionX)
                
                var positionXMax = CGPoint.zero
                positionXMax = .init(x: range[i + 1], y: 0)
                trans.pointValueToPixel(&positionXMax)
                _dataSetShadowRectBuffer.origin.x = positionX.x
                _dataSetShadowRectBuffer.size.width = positionXMax.x - positionX.x
                _dataSetShadowRectBuffer.origin.y = viewPortHandler.contentTop
                _dataSetShadowRectBuffer.size.height = viewPortHandler.chartHeight
                
                context.setFillColor(backColor.cgColor)
                context.fill(_dataSetShadowRectBuffer)
                
                if let image = dataSet.backgroundFilledImage, let cgImage = image.cgImage {
                    let posX: CGFloat = positionX.x + 8
                    let widthHeight: CGFloat = 12
                    
                    if (positionXMax.x - positionX.x) > widthHeight + 8 {
                        context.drawFlipped(cgImage, in: .init(x: CGFloat(Int(posX)), y: CGFloat(Int(viewPortHandler.contentTop)) + 8, width: widthHeight, height: widthHeight))
                    }
                }
            }
        }
    }
}
