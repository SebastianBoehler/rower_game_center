import SwiftUI

struct StrokeShapeGraphView: View {
    let referenceCurve: [Double]
    let liveCurve: [Double]?
    let historicalCurves: [[Double]]
    let tint: Color
    let liveCurveIsPreview: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.secondaryGroupedBackground,
                                AppTheme.tertiaryGroupedBackground,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Canvas { context, size in
                    drawGrid(in: &context, size: size)
                    drawHistoricalCurves(in: &context, size: size)
                    drawReferenceCurve(in: &context, size: size)
                    drawLiveCurve(in: &context, size: size)
                }

                overlayChrome
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stroke shape chart")
    }

    private var overlayChrome: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                legendChip(title: "Optimal", tint: .secondary)

                if !historicalCurves.isEmpty {
                    legendChip(title: "Last 10", tint: tint.opacity(0.35))
                }

                if liveCurve != nil {
                    legendChip(title: "Current", tint: tint)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Spacer()

            HStack {
                Text("Catch")
                Spacer()
                Text("Mid drive")
                Spacer()
                Text("Release")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
        }
    }

    private func legendChip(title: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
    }

    private func drawGrid(in context: inout GraphicsContext, size: CGSize) {
        let horizontalGuideCount = 4
        let verticalGuideCount = 4
        let padding = chartPadding(for: size)
        let gridColor = AppTheme.separator.opacity(0.12)

        for index in 0 ... horizontalGuideCount {
            let progress = CGFloat(index) / CGFloat(horizontalGuideCount)
            let y = padding.top + ((size.height - padding.top - padding.bottom) * progress)
            var path = Path()
            path.move(to: CGPoint(x: padding.leading, y: y))
            path.addLine(to: CGPoint(x: size.width - padding.trailing, y: y))
            context.stroke(path, with: .color(gridColor), style: StrokeStyle(lineWidth: 1))
        }

        for index in 0 ... verticalGuideCount {
            let progress = CGFloat(index) / CGFloat(verticalGuideCount)
            let x = padding.leading + ((size.width - padding.leading - padding.trailing) * progress)
            var path = Path()
            path.move(to: CGPoint(x: x, y: padding.top))
            path.addLine(to: CGPoint(x: x, y: size.height - padding.bottom))
            context.stroke(path, with: .color(gridColor), style: StrokeStyle(lineWidth: 1))
        }
    }

    private func drawReferenceCurve(in context: inout GraphicsContext, size: CGSize) {
        let path = curvePath(for: referenceCurve, in: size)
        context.stroke(
            path,
            with: .color(.secondary),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 6])
        )
    }

    private func drawHistoricalCurves(in context: inout GraphicsContext, size: CGSize) {
        let curves = if liveCurve == nil || liveCurveIsPreview {
            historicalCurves
        } else {
            Array(historicalCurves.dropLast())
        }
        guard !curves.isEmpty else { return }

        for (index, curve) in curves.enumerated() {
            let progress = Double(index + 1) / Double(curves.count)
            let opacity = 0.08 + (progress * 0.26)
            let lineWidth = 1.2 + (progress * 0.8)
            let path = curvePath(for: curve, in: size)

            context.stroke(
                path,
                with: .color(tint.opacity(opacity)),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func drawLiveCurve(in context: inout GraphicsContext, size: CGSize) {
        guard let liveCurve else { return }

        let strokePath = curvePath(for: liveCurve, in: size)
        let fillPath = filledCurvePath(for: liveCurve, in: size)

        context.fill(
            fillPath,
            with: .linearGradient(
                Gradient(colors: [tint.opacity(0.22), tint.opacity(0.02)]),
                startPoint: CGPoint(x: size.width / 2, y: chartPadding(for: size).top),
                endPoint: CGPoint(x: size.width / 2, y: size.height - chartPadding(for: size).bottom)
            )
        )

        context.stroke(
            strokePath,
            with: .color(tint),
            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
        )

        if let peakPoint = peakPoint(for: liveCurve, in: size) {
            context.fill(Path(ellipseIn: CGRect(x: peakPoint.x - 5, y: peakPoint.y - 5, width: 10, height: 10)), with: .color(tint))
        }
    }

    private func curvePath(for values: [Double], in size: CGSize) -> Path {
        let padding = chartPadding(for: size)
        let chartWidth = size.width - padding.leading - padding.trailing
        let chartHeight = size.height - padding.top - padding.bottom

        return Path { path in
            for (index, value) in values.enumerated() {
                let progress = CGFloat(index) / CGFloat(max(values.count - 1, 1))
                let point = CGPoint(
                    x: padding.leading + (chartWidth * progress),
                    y: padding.top + (chartHeight * CGFloat(1 - value))
                )

                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
    }

    private func filledCurvePath(for values: [Double], in size: CGSize) -> Path {
        let padding = chartPadding(for: size)
        let baselineY = size.height - padding.bottom
        var path = curvePath(for: values, in: size)

        path.addLine(to: CGPoint(x: size.width - padding.trailing, y: baselineY))
        path.addLine(to: CGPoint(x: padding.leading, y: baselineY))
        path.closeSubpath()

        return path
    }

    private func peakPoint(for values: [Double], in size: CGSize) -> CGPoint? {
        guard let peakIndex = values.indices.max(by: { values[$0] < values[$1] }) else {
            return nil
        }

        let padding = chartPadding(for: size)
        let chartWidth = size.width - padding.leading - padding.trailing
        let chartHeight = size.height - padding.top - padding.bottom
        let progress = CGFloat(peakIndex) / CGFloat(max(values.count - 1, 1))

        return CGPoint(
            x: padding.leading + (chartWidth * progress),
            y: padding.top + (chartHeight * CGFloat(1 - values[peakIndex]))
        )
    }

    private func chartPadding(for size: CGSize) -> EdgeInsets {
        let top = max(70, size.height * 0.18)
        return EdgeInsets(top: top, leading: 20, bottom: 34, trailing: 20)
    }
}
