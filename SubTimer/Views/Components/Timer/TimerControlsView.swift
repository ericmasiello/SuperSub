//
//  TimerControlsView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for controlling the timer (start/pause)
struct TimerControlsView: View {
    // MARK: - Properties

    let isRunning: Bool
    let onToggle: () -> Void
    let onReset: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                HStack {
                    Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 30))
                    Text(isRunning ? "Pause" : "Start")
                        .font(.title2)
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isRunning ? Color.appOrange : Color.green)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            Button(action: onReset) {
                HStack {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 30))
                    Text("Reset")
                        .font(.title2)
                        .bold()
                }
            }
            .padding()
            .background(Color.gray)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview("Timer Running") {
    TimerControlsView(
        isRunning: true,
        onToggle: { print("Toggle tapped") },
        onReset: { print("Reest tapepd ") }
    )
    .padding()
}

#Preview("Timer Paused") {
    TimerControlsView(
        isRunning: false,
        onToggle: { print("Toggle tapped") },
        onReset: { print("Reest tapepd ") }
    )
    .padding()
}
