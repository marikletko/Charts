//
//  GenericCandleLineChartRenderer.swift
//  Charts
//
//  Created by KIRYL LIOTKA on 21/10/2024.
//
import Foundation
import CoreGraphics

final class GenericCandleLineChartRenderer: CandleStickChartRenderer {
    
    override func drawDataSet(context: CGContext, dataSet: CandleChartDataSetProtocol) {
        guard let dataProvider = dataProvider else { return }
        guard dataProvider.isMultiTouchActive else {
            return super.drawDataSet(context: context, dataSet: dataSet)
        }
        
        if dataProvider.highlighted.count > 1, let firstHighlight = dataProvider.highlighted.first, let secondHighlight = dataProvider.highlighted.last {
            
            let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
            
            let phaseY = animator.phaseY
            let barSpace = dataSet.barSpace
            let showCandleBar = dataSet.showCandleBar
            
            _xBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)
            
            context.saveGState()
            
            context.setLineWidth(dataSet.shadowWidth)
            
            let min = Int(min(firstHighlight.x, secondHighlight.x))
            let max = Int(max(firstHighlight.x, secondHighlight.x))
            
            for j in _xBounds
            {
                // get the entry
                guard let e = dataSet.entryForIndex(j) as? CandleChartDataEntry else { continue }
                
                let xPos = e.x
                
                let open = e.open
                let close = e.close
                let high = e.high
                let low = e.low
                
                let doesContainMultipleDataSets = (dataProvider.candleData?.count ?? 1) > 1
                var accessibilityMovementDescription = "neutral"
                var accessibilityRect = CGRect(x: CGFloat(xPos) + 0.5 - barSpace,
                                               y: CGFloat(low * phaseY),
                                               width: (2 * barSpace) - 1.0,
                                               height: (CGFloat(abs(high - low) * phaseY)))
                trans.rectValueToPixel(&accessibilityRect)

                if showCandleBar
                {
                    // calculate the shadow
                    
                    _shadowPoints[0].x = CGFloat(xPos)
                    _shadowPoints[1].x = CGFloat(xPos)
                    _shadowPoints[2].x = CGFloat(xPos)
                    _shadowPoints[3].x = CGFloat(xPos)
                    
                    if open > close
                    {
                        _shadowPoints[0].y = CGFloat(high * phaseY)
                        _shadowPoints[1].y = CGFloat(open * phaseY)
                        _shadowPoints[2].y = CGFloat(low * phaseY)
                        _shadowPoints[3].y = CGFloat(close * phaseY)
                    }
                    else if open < close
                    {
                        _shadowPoints[0].y = CGFloat(high * phaseY)
                        _shadowPoints[1].y = CGFloat(close * phaseY)
                        _shadowPoints[2].y = CGFloat(low * phaseY)
                        _shadowPoints[3].y = CGFloat(open * phaseY)
                    }
                    else
                    {
                        _shadowPoints[0].y = CGFloat(high * phaseY)
                        _shadowPoints[1].y = CGFloat(open * phaseY)
                        _shadowPoints[2].y = CGFloat(low * phaseY)
                        _shadowPoints[3].y = _shadowPoints[1].y
                    }
                    
                    trans.pointValuesToPixel(&_shadowPoints)
                    
                    // draw the shadows
                    
                    var shadowColor: NSUIColor! = nil
                    if dataSet.shadowColorSameAsCandle
                    {
                        
                        if min >= j || max <= j {
                            shadowColor = dataSet.neutralColor ?? dataSet.color(atIndex: j)
                        } else {
                            if open > close
                            {
                                shadowColor = dataSet.decreasingColor ?? dataSet.color(atIndex: j)
                            }
                            else if open < close
                            {
                                shadowColor = dataSet.increasingColor ?? dataSet.color(atIndex: j)
                            }
                            else
                            {
                                shadowColor = dataSet.neutralColor ?? dataSet.color(atIndex: j)
                            }
                        }
                    }
                    
                    if shadowColor === nil
                    {
                        shadowColor = dataSet.shadowColor ?? dataSet.color(atIndex: j)
                    }
                    
                    context.setStrokeColor(shadowColor.cgColor)
                    context.strokeLineSegments(between: _shadowPoints)
                    
                    // calculate the body
                    
                    _bodyRect.origin.x = CGFloat(xPos) - 0.5 + barSpace
                    _bodyRect.origin.y = CGFloat(close * phaseY)
                    _bodyRect.size.width = (CGFloat(xPos) + 0.5 - barSpace) - _bodyRect.origin.x
                    _bodyRect.size.height = CGFloat(open * phaseY) - _bodyRect.origin.y
                    
                    trans.rectValueToPixel(&_bodyRect)
                    
                    // draw body differently for increasing and decreasing entry
                    
                    if min >= j || max <= j {
                        let color = dataSet.neutralColor ?? dataSet.color(atIndex: j)
                        
                        context.setStrokeColor(color.cgColor)
                        context.stroke(_bodyRect)
                    } else {
                        if open > close
                        {
                            accessibilityMovementDescription = "decreasing"
                            
                            let color = dataSet.decreasingColor ?? dataSet.color(atIndex: j)
                            
                            if dataSet.isDecreasingFilled
                            {
                                context.setFillColor(color.cgColor)
                                context.fill(_bodyRect)
                            }
                            else
                            {
                                context.setStrokeColor(color.cgColor)
                                context.stroke(_bodyRect)
                            }
                        }
                        else if open < close
                        {
                            accessibilityMovementDescription = "increasing"
                            
                            let color = dataSet.increasingColor ?? dataSet.color(atIndex: j)
                            
                            if dataSet.isIncreasingFilled
                            {
                                context.setFillColor(color.cgColor)
                                context.fill(_bodyRect)
                            }
                            else
                            {
                                context.setStrokeColor(color.cgColor)
                                context.stroke(_bodyRect)
                            }
                        }
                        else
                        {
                            let color = dataSet.neutralColor ?? dataSet.color(atIndex: j)
                            
                            context.setStrokeColor(color.cgColor)
                            context.stroke(_bodyRect)
                        }
                    }
                }
                else
                {
                    _rangePoints[0].x = CGFloat(xPos)
                    _rangePoints[0].y = CGFloat(high * phaseY)
                    _rangePoints[1].x = CGFloat(xPos)
                    _rangePoints[1].y = CGFloat(low * phaseY)

                    _openPoints[0].x = CGFloat(xPos) - 0.5 + barSpace
                    _openPoints[0].y = CGFloat(open * phaseY)
                    _openPoints[1].x = CGFloat(xPos)
                    _openPoints[1].y = CGFloat(open * phaseY)

                    _closePoints[0].x = CGFloat(xPos) + 0.5 - barSpace
                    _closePoints[0].y = CGFloat(close * phaseY)
                    _closePoints[1].x = CGFloat(xPos)
                    _closePoints[1].y = CGFloat(close * phaseY)
                    
                    trans.pointValuesToPixel(&_rangePoints)
                    trans.pointValuesToPixel(&_openPoints)
                    trans.pointValuesToPixel(&_closePoints)
                    
                    // draw the ranges
                    var barColor: NSUIColor! = nil

                    if min >= j || max <= j {
                        barColor = dataSet.neutralColor ?? dataSet.color(atIndex: j)
                    } else {
                        if open > close
                        {
                            accessibilityMovementDescription = "decreasing"
                            barColor = dataSet.decreasingColor ?? dataSet.color(atIndex: j)
                        }
                        else if open < close
                        {
                            accessibilityMovementDescription = "increasing"
                            barColor = dataSet.increasingColor ?? dataSet.color(atIndex: j)
                        }
                        else
                        {
                            barColor = dataSet.neutralColor ?? dataSet.color(atIndex: j)
                        }
                    }
                    
                    context.setStrokeColor(barColor.cgColor)
                    context.strokeLineSegments(between: _rangePoints)
                    context.strokeLineSegments(between: _openPoints)
                    context.strokeLineSegments(between: _closePoints)
                }

                let axElement = createAccessibleElement(withIndex: j,
                                                        container: dataProvider,
                                                        dataSet: dataSet)
                { (element) in
                    element.accessibilityLabel = "\(doesContainMultipleDataSets ? "\(dataSet.label ?? "Dataset")" : "") " + "\(xPos) - \(accessibilityMovementDescription). low: \(low), high: \(high), opening: \(open), closing: \(close)"
                    element.accessibilityFrame = accessibilityRect
                }

                accessibleChartElements.append(axElement)

            }

            // Post this notification to let VoiceOver account for the redrawn frames
            accessibilityPostLayoutChangedNotification()

            context.restoreGState()
            
        } else {
            return super.drawDataSet(context: context, dataSet: dataSet)
        }
    }
}
