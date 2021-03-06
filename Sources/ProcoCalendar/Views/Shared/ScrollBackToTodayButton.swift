// Kevin Li - 7:14 PM - 6/14/20

import SwiftUI

struct ScrollBackToTodayButton: View {

    let scrollBackToToday: () -> Void
    let color: Color

    var body: some View {
        Button(action: scrollBackToToday) {
            Image(systemName: "arrow.uturn.backward.circle")
                .resizable()
                .frame(width: 30, height: 25)
                .foregroundColor(color)
        }
        .animation(.easeInOut)
    }
}
