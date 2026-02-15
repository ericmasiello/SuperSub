//
//  MainTabView.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Player.self, AppConfiguration.self, Session.self], inMemory: true)
}
