//
//  SubstitutionButtonView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for the main substitution button
struct SubstitutionButtonView: View {
    // MARK: - Properties

    let canPerformSubstitution: Bool
    let onSubstitute: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onSubstitute) {
            HStack {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.title2)
                Text("Substitute")
                    .font(.title2)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(canPerformSubstitution ? Color.blue : Color.gray.opacity(0.3))
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
        .disabled(!canPerformSubstitution)
    }
}

// MARK: - Preview

#Preview("Enabled") {
    SubstitutionButtonView(
        canPerformSubstitution: true,
        onSubstitute: { print("Substitute tapped") }
    )
    .padding()
}

#Preview("Disabled") {
    SubstitutionButtonView(
        canPerformSubstitution: false,
        onSubstitute: { print("Substitute tapped") }
    )
    .padding()
}

#Preview("In Context - Enabled") {
    VStack(spacing: 20) {
        Text("Active Players: 4")
        Text("Bench Players: 3")

        SubstitutionButtonView(
            canPerformSubstitution: true,
            onSubstitute: { print("Substitute tapped") }
        )
    }
    .padding()
}

#Preview("In Context - Disabled") {
    VStack(spacing: 20) {
        Text("Active Players: 4")
        Text("Bench Players: 0")

        SubstitutionButtonView(
            canPerformSubstitution: false,
            onSubstitute: { print("Substitute tapped") }
        )
    }
    .padding()
}
