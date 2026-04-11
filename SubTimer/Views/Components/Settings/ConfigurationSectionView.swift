//
//  ConfigurationSectionView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for the configuration section in settings
struct ConfigurationSectionView: View {
    // MARK: - Properties

    let activePlayersCount: Int
    let maxPlayers: Int
    let preferredTimeSeconds: Int
    let onActivePlayersChange: (Int) -> Void
    let onPreferredTimeChange: (Int) -> Void

    // MARK: - Body

    var body: some View {
        Section {
            ActivePlayersStepperView(
                activePlayersCount: activePlayersCount,
                maxPlayers: maxPlayers,
                onChange: onActivePlayersChange
            )

            PreferredTimePickerView(
                preferredTimeSeconds: preferredTimeSeconds,
                onChange: onPreferredTimeChange
            )
        } header: {
            Text("Configuration")
        } footer: {
            if maxPlayers < activePlayersCount {
                Text(
                    "⚠️ Active players automatically adjusted to match available players (\(maxPlayers))"
                )
                .foregroundStyle(.orange)
            }
        }
    }
}

// MARK: - Preview

#Preview("Normal Configuration") {
    Form {
        ConfigurationSectionView(
            activePlayersCount: 4,
            maxPlayers: 8,
            preferredTimeSeconds: 180,
            onActivePlayersChange: { newValue in print("Active players: \(newValue)") },
            onPreferredTimeChange: { newValue in print("Preferred time: \(newValue)") }
        )
    }
}

#Preview("Warning State - Too Few Players") {
    Form {
        ConfigurationSectionView(
            activePlayersCount: 5,
            maxPlayers: 3,
            preferredTimeSeconds: 120,
            onActivePlayersChange: { newValue in print("Active players: \(newValue)") },
            onPreferredTimeChange: { newValue in print("Preferred time: \(newValue)") }
        )
    }
}

#Preview("Minimum Settings") {
    Form {
        ConfigurationSectionView(
            activePlayersCount: 1,
            maxPlayers: 1,
            preferredTimeSeconds: 30,
            onActivePlayersChange: { newValue in print("Active players: \(newValue)") },
            onPreferredTimeChange: { newValue in print("Preferred time: \(newValue)") }
        )
    }
}

#Preview("Maximum Settings") {
    Form {
        ConfigurationSectionView(
            activePlayersCount: 15,
            maxPlayers: 15,
            preferredTimeSeconds: 1800,
            onActivePlayersChange: { newValue in print("Active players: \(newValue)") },
            onPreferredTimeChange: { newValue in print("Preferred time: \(newValue)") }
        )
    }
}

#Preview("Typical Game Settings") {
    Form {
        ConfigurationSectionView(
            activePlayersCount: 5,
            maxPlayers: 10,
            preferredTimeSeconds: 300,
            onActivePlayersChange: { newValue in print("Active players: \(newValue)") },
            onPreferredTimeChange: { newValue in print("Preferred time: \(newValue)") }
        )
    }
}
