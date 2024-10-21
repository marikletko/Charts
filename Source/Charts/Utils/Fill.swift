//
//  Fill.swift
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

@objc(ChartFill)
public protocol Fill
{

    /// Draws the provided path in filled mode with the provided area
    @objc func fillPath(context: CGContext, transformer: Transformer)
}

@objc(ChartEmptyFill)
public class EmptyFill: NSObject, Fill
{

    public func fillPath(context: CGContext, transformer: Transformer) { }
}

@objc(ChartColorFill)
public class ColorFill: NSObject, Fill
{

    @objc public let color: CGColor

    @objc public init(cgColor: CGColor)
    {
        self.color = cgColor
        super.init()
    }

    @objc public convenience init(color: NSUIColor)
    {
        self.init(cgColor: color.cgColor)
    }

    public func fillPath(context: CGContext, transformer: Transformer)
    {
        context.saveGState()
        defer { context.restoreGState() }

        context.setFillColor(color)
        context.fillPath()
    }
}

@objc(ChartImageFill)
public class ImageFill: NSObject, Fill
{

    @objc public let image: CGImage
    @objc public let isTiled: Bool

    @objc public init(cgImage: CGImage, isTiled: Bool = false)
    {
        image = cgImage
        self.isTiled = isTiled
        super.init()
    }

    @objc public convenience init(image: NSUIImage, isTiled: Bool = false)
    {
        self.init(cgImage: image.cgImage!, isTiled: isTiled)
    }

    public func fillPath(context: CGContext, transformer: Transformer)
    {
        context.saveGState()
        defer { context.restoreGState() }

        context.clip()
        context.draw(image, in: transformer.viewPortHandler.contentRect, byTiling: isTiled)
    }
}

@objc(ChartLayerFill)
public class LayerFill: NSObject, Fill
{

    @objc public let layer: CGLayer

    @objc public init(layer: CGLayer)
    {
        self.layer = layer
        super.init()
    }

    public func fillPath(context: CGContext, transformer: Transformer)
    {
        context.saveGState()
        defer { context.restoreGState() }

        context.clip()
        context.draw(layer, in: transformer.viewPortHandler.contentRect)
    }
}

@objc(ChartLinearGradientFill)
public class LinearGradientFill: NSObject, Fill
{

    @objc public let gradient: CGGradient
    @objc public let angle: CGFloat

    @objc public init(gradient: CGGradient, angle: CGFloat = 0)
    {
        self.gradient = gradient
        self.angle = angle
        super.init()
    }

    public func fillPath(context: CGContext, transformer: Transformer)
    {
        let rect = transformer.viewPortHandler.contentRect
        context.saveGState()
        defer { context.restoreGState() }
        let radians = (360.0 - angle).DEG2RAD
        let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
        let xAngleDelta = cos(radians) * rect.width / 2.0
        let yAngleDelta = sin(radians) * rect.height / 2.0
        let startPoint = CGPoint(
            x: centerPoint.x - xAngleDelta,
            y: centerPoint.y - yAngleDelta
        )
        let endPoint = CGPoint(
            x: centerPoint.x + xAngleDelta,
            y: centerPoint.y + yAngleDelta
        )
        context.clip()
        context.drawLinearGradient(
            gradient,
            start: startPoint,
            end: endPoint,
            options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
        )
    }
}

@objc(ChartLinearMultiColorGradientFill)
public class LinearMultiColorGradientFill: LinearGradientFill
{
    @objc public let middleY: CGFloat
    public init(gradient: CGGradient, angle: CGFloat = 0, middleY: CGFloat) {
        self.middleY = middleY
        super.init(gradient: gradient, angle: angle)
    }
    public override func fillPath(context: CGContext, transformer: Transformer)
    {
        let rect = transformer.viewPortHandler.contentRect
        context.saveGState()
        defer { context.restoreGState() }

        let radians = (360.0 - angle).DEG2RAD
        
        let centerPoint = CGPoint(x: rect.midX, y: transformer.pixelForValues(x: 0, y: middleY).y)
        let xAngleDelta = cos(radians) * rect.width / 2.0
        let yAngleDelta = sin(radians) * rect.height / 2.0
        let startPoint = CGPoint(
            x: centerPoint.x - xAngleDelta,
            y: centerPoint.y - yAngleDelta
        )
        let endPoint = CGPoint(
            x: centerPoint.x + xAngleDelta,
            y: centerPoint.y + yAngleDelta
        )
        context.clip()
        context.drawLinearGradient(
            gradient,
            start: startPoint,
            end: endPoint,
            options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
        )
    }
}

@objc(ChartPriceLinearMultiColorGradientFill)
public class PriceLinearMultiColorGradientFill: NSObject, Fill
{
    @objc public let middleY: CGFloat
    @objc public let gradient: CGGradient
    @objc public let angle: Double
    public init(gradient: CGGradient, angle: Double = 0, middleY: CGFloat) {
        self.gradient = gradient
        self.angle = angle
        self.middleY = middleY
    }
    public func fillPath(context: CGContext, transformer: Transformer)
    {
        let rect = transformer.viewPortHandler.contentRect
        context.saveGState()
        defer { context.restoreGState() }

        let radians = (360.0 - angle).DEG2RAD
        
        let centerPoint = CGPoint(x: rect.midX, y: transformer.pixelForValues(x: 0, y: middleY).y)
        let xAngleDelta = cos(radians) * rect.width / 2.0
        let yAngleDelta = sin(radians) * rect.height / 2.0
        let startPoint = CGPoint(
            x: centerPoint.x - xAngleDelta,
            y: centerPoint.y - yAngleDelta
        )
        let endPoint = CGPoint(
            x: centerPoint.x + xAngleDelta,
            y: centerPoint.y + yAngleDelta
        )
        context.clip()
        
        context.drawLinearGradient(
            gradient,
            start: startPoint,
            end: endPoint,
            options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
        )
    }
}


@objc(ChartRadialGradientFill)
public class RadialGradientFill: NSObject, Fill
{

    @objc public let gradient: CGGradient
    @objc public let startOffsetPercent: CGPoint
    @objc public let endOffsetPercent: CGPoint
    @objc public let startRadiusPercent: CGFloat
    @objc public let endRadiusPercent: CGFloat

    @objc public init(
        gradient: CGGradient,
        startOffsetPercent: CGPoint,
        endOffsetPercent: CGPoint,
        startRadiusPercent: CGFloat,
        endRadiusPercent: CGFloat)
    {
        self.gradient = gradient
        self.startOffsetPercent = startOffsetPercent
        self.endOffsetPercent = endOffsetPercent
        self.startRadiusPercent = startRadiusPercent
        self.endRadiusPercent = endRadiusPercent
        super.init()
    }

    @objc public convenience init(gradient: CGGradient)
    {
        self.init(
            gradient: gradient,
            startOffsetPercent: .zero,
            endOffsetPercent: .zero,
            startRadiusPercent: 0,
            endRadiusPercent: 1
        )
    }

    @objc public func fillPath(context: CGContext, transformer: Transformer)
    {
        let rect = transformer.viewPortHandler.contentRect
        context.saveGState()
        defer { context.restoreGState() }

        let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height) / 2.0

        context.clip()
        context.drawRadialGradient(
            gradient,
            startCenter: CGPoint(
                x: centerPoint.x + rect.width * startOffsetPercent.x,
                y: centerPoint.y + rect.height * startOffsetPercent.y
            ),
            startRadius: radius * startRadiusPercent,
            endCenter: CGPoint(
                x: centerPoint.x + rect.width * endOffsetPercent.x,
                y: centerPoint.y + rect.height * endOffsetPercent.y
            ),
            endRadius: radius * endRadiusPercent,
            options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
        )
    }
}
