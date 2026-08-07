//
//  RosterMembership.swift
//  SubTimer
//
//  Created by SubTimer on 8/6/26.
//

import Foundation
import SwiftData

@Model
final class RosterMembership {
    var id = UUID()
    var position: String?

    @Relationship(deleteRule: .nullify)
    var player: Player?

    @Relationship(deleteRule: .nullify)
    var team: Team?

    init(
        id: UUID = UUID(),
        position: String? = nil,
        player: Player? = nil,
        team: Team? = nil
    ) {
        self.id = id
        self.position = position
        self.player = player
        self.team = team
    }
}
