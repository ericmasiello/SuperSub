//
//  SessionManagementSectionView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI

/// Component for the session management section in settings
struct SessionManagementSectionView: View {
    // MARK: - Properties

    let onViewHistory: () -> Void
    let onClearSession: () -> Void

    // MARK: - Body

    var body: some View {
        Section {
            Button {
                onViewHistory()
            } label: {
                Label("Session History", systemImage: "clock.arrow.circlepath")
            }

            Button(role: .destructive) {
                onClearSession()
            } label: {
                Label("Clear Current Session", systemImage: "trash")
            }
        } header: {
            Text("Session Management")
        }
    }
}

// MARK: - Preview

#Preview("Normal State") {
    Form {
        SessionManagementSectionView(
            onViewHistory: { print("View history") },
            onClearSession: { print("Clear session") }
        )
    }
}

#Preview("With Other Sections") {
    Form {
        Section("Players") {
            Text("Player 1")
            Text("Player 2")
        }

        SessionManagementSectionView(
            onViewHistory: { print("View history") },
            onClearSession: { print("Clear session") }
        )
    }
}

#Preview("Multiple Contexts") {
    Form {
        SessionManagementSectionView(
            onViewHistory: { print("View history") },
            onClearSession: { print("Clear session") }
        )

        Section("Configuration") {
            Text("Setting 1")
            Text("Setting 2")
        }
    }
}
