import SwiftUI

struct WearProgressBar: View {
    let percentage: Double
    var height: CGFloat = 8

    private var color: Color {
        switch percentage {
        case 0..<0.5:     return .green
        case 0.5..<0.75:  return .yellow
        case 0.75..<0.9:  return .orange
        default:          return .red
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geometry.size.width * min(percentage, 1.0))
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 16) {
        WearProgressBar(percentage: 0.3)
        WearProgressBar(percentage: 0.6)
        WearProgressBar(percentage: 0.85)
        WearProgressBar(percentage: 1.0)
    }
    .padding()
}
