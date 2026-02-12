import SwiftUI

struct PaperBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Theme.background

                Canvas { context, size in
                    let spacing: CGFloat = 28
                    var path = Path()
                    var y: CGFloat = 0
                    while y < size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += spacing
                    }
                    context.stroke(path, with: .color(Theme.subtle.opacity(0.22)), lineWidth: 0.5)
                }
                .opacity(0.35)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }
}
