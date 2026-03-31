import SwiftUI

struct TempleErgSceneBackdrop: View {
    let currentReading: TempleErgActionReading
    let size: CGSize

    var body: some View {
        ZStack {
            atmosphere
            ruinsBackdrop
            trackBed
            actionLane
        }
    }

    private var atmosphere: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.09, blue: 0.18),
                    Color(red: 0.12, green: 0.20, blue: 0.30),
                    Color(red: 0.42, green: 0.24, blue: 0.15),
                    Color(red: 0.66, green: 0.41, blue: 0.20),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color(red: 1.00, green: 0.78, blue: 0.42).opacity(0.9))
                .frame(width: 260, height: 260)
                .blur(radius: 6)
                .offset(x: 110, y: -180)

            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.black.opacity(0.16), Color.black.opacity(0.34)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 260)
            }
        }
    }

    private var ruinsBackdrop: some View {
        ZStack(alignment: .top) {
            TempleErgTempleSilhouette()
                .fill(Color.black.opacity(0.28))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            HStack(spacing: 22) {
                ForEach(0 ..< 5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(index == 2 ? 0.10 : 0.06))
                        .frame(width: 42, height: index.isMultiple(of: 2) ? 186 : 160)
                        .overlay(alignment: .top) {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 56, height: 10)
                                .offset(y: -6)
                        }
                }
            }
            .padding(.top, 72)
        }
    }

    private var trackBed: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                TempleErgLaneShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.10, blue: 0.11),
                                Color(red: 0.18, green: 0.14, blue: 0.13),
                                Color(red: 0.30, green: 0.22, blue: 0.17),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                TempleErgLaneShape()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1.2)

                VStack(spacing: 18) {
                    ForEach(0 ..< 7, id: \.self) { index in
                        Capsule()
                            .fill(Color.white.opacity(0.10 - (Double(index) * 0.01)))
                            .frame(width: 90 + CGFloat(index * 22), height: 8)
                    }
                }
                .padding(.top, 70)

                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        ForEach(0 ..< 14, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.black.opacity(0.18))
                                .frame(width: 34, height: 58)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.8)
                                }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .frame(height: 270)
        }
    }

    private var actionLane: some View {
        VStack {
            Spacer()

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            currentReading.tint.opacity(0.30),
                            currentReading.tint.opacity(0.06),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(currentReading.tint.opacity(0.46), style: StrokeStyle(lineWidth: 2, dash: [10, 8]))
                }
                .frame(width: size.width * 0.18, height: size.height * 0.58)
                .overlay(alignment: .top) {
                    TempleErgActionChip(currentReading: currentReading)
                        .padding(.top, 18)
                }
                .padding(.leading, size.width * 0.08)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 34)
        }
    }
}

struct TempleErgActionChip: View {
    let currentReading: TempleErgActionReading

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: currentReading.systemImage)
            Text(currentReading.title.uppercased())
        }
        .font(.caption.weight(.black))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(currentReading.tint.opacity(0.42), in: Capsule())
        .overlay {
            Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
    }
}

struct TempleErgLaneShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + 28, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX - 82, y: rect.minY + 36))
            path.addLine(to: CGPoint(x: rect.midX + 82, y: rect.minY + 36))
            path.addLine(to: CGPoint(x: rect.maxX - 28, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

struct TempleErgTempleSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let top = rect.minY + 46
            let center = rect.midX
            path.move(to: CGPoint(x: rect.minX + 40, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + 90, y: top + 80))
            path.addLine(to: CGPoint(x: center - 96, y: top + 80))
            path.addLine(to: CGPoint(x: center - 50, y: top + 22))
            path.addLine(to: CGPoint(x: center, y: top))
            path.addLine(to: CGPoint(x: center + 50, y: top + 22))
            path.addLine(to: CGPoint(x: center + 96, y: top + 80))
            path.addLine(to: CGPoint(x: rect.maxX - 90, y: top + 80))
            path.addLine(to: CGPoint(x: rect.maxX - 40, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

enum TempleErgScene {
    static let spawnPosition = 1.12
    static let playerZonePosition = 0.22
}
