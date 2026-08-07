//
//  Stint.swift
//  SubTimer
//
//  Created by SubTimer on 8/6/26.
//

import Foundation
import SwiftData

@Model
final class Stint {
    var id = UUID()
    var startDate = Date()
    var endDate: Date?
    var position: String?

    @Relationship(deleteRule: .nullify)
    var player: Player?

    @Relationship(deleteRule: .nullify)
    var game: Game?

    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        position: String? = nil,
        player: Player? = nil,
        game: Game? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.position = position
        self.player = player
        self.game = game
    }
}
