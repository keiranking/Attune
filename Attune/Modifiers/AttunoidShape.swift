import SwiftUI

struct Attunoid: Shape {
    var cornerRadius: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        let h = rect.height
        let r = min(cornerRadius, h / 2)
        let rForBD = r * 1.67

        let maxXInsetForBD = rect.midY / tan(Angle(degrees: 50).radians)

        let a = CGPoint(x: rect.minX, y: rect.minY)
        let b = CGPoint(x: rect.maxX - maxXInsetForBD, y: rect.minY)
        let c = CGPoint(x: rect.maxX, y: rect.midY)
        let d = CGPoint(x: rect.maxX - maxXInsetForBD, y: rect.maxY)
        let e = CGPoint(x: rect.minX, y: rect.maxY)

        let bdXInsetForCornersBD = tan(Angle(degrees: 25).radians) * rForBD
        let maxXInsetForCornerC = r / sin(Angle(degrees: 50).radians)

        let originA = CGPoint(x: a.x + r, y: a.y + r)
        let originB = CGPoint(x: b.x - bdXInsetForCornersBD, y: b.y + rForBD)
        let originC = CGPoint(x: c.x - maxXInsetForCornerC, y: c.y)
        let originD = CGPoint(x: d.x - bdXInsetForCornersBD, y: d.y - rForBD)
        let originE = CGPoint(x: e.x + r, y: e.y - r)

        var p = Path()

        p.move(to: CGPoint(x: rect.minX + r, y: rect.minY)) // start top-left

        p.addArc( // 50° outside, 130° inside
            center: originB,
            radius: rForBD,
            startAngle: .degrees(-90),
            endAngle: .degrees(-40),
            clockwise: false
        )

        p.addArc( // 80° outside, 100° inside
            center: originC,
            radius: r,
            startAngle: .degrees(-40),
            endAngle: .degrees(40),
            clockwise: false
        )

        p.addArc( // 50° outside, 130° inside
            center: originD,
            radius: rForBD,
            startAngle: .degrees(40),
            endAngle: .degrees(90),
            clockwise: false
        )

        p.addArc(
            center: originE,
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        p.addArc(
            center: originA,
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        p.closeSubpath() // interpolate connecting lines
        return p
    }
}


#Preview {
    ZStack {
        Attunoid(cornerRadius:  0).fill(.red.opacity(0.5))
        Attunoid(cornerRadius:  20).fill(.blue.opacity(0.5))
        Attunoid(cornerRadius:  40).fill(.green.opacity(0.5))
    }
    .padding(50)
    .frame(width: 400, height: 200)
}
