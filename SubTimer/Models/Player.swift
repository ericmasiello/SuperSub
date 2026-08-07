//
//  Player.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import Foundation
import SwiftData

@Model
final class Player {
    static let defaultCurrentPlayDuration: TimeInterval = 0
    static let defaultTotalPlayTime: TimeInterval = 0
    static let defaultStatus: PlayerStatus = .benched
    static let defaultSortOrder = 0

    var id = UUID()
    var name: String = ""
    var createdDate = Date()
    var currentPlayDuration = Player.defaultCurrentPlayDuration
    var totalPlayTime = Player.defaultTotalPlayTime
    var status = Player.defaultStatus
    var sortOrder = Player.defaultSortOrder
    var activatedAtDate = Date()

    // Dormant, additive relationships from #57 — nothing reads or writes
    // these yet. Required as CloudKit-compatible inverses for
    // `RosterMembership.player` / `Stint.player` (see #55).
    @Relationship(deleteRule: .nullify, inverse: \RosterMembership.player)
    var rosterMemberships: [RosterMembership]?

    @Relationship(deleteRule: .nullify, inverse: \Stint.player)
    var stints: [Stint]?

    init(
        id: UUID = UUID(),
        name: String,
        createdDate: Date = Date(),
        currentPlayDuration: TimeInterval = Player.defaultCurrentPlayDuration,
        totalPlayTime: TimeInterval = Player.defaultTotalPlayTime,
        status: PlayerStatus = Player.defaultStatus,
        sortOrder: Int = Player.defaultSortOrder,
        activatedAtDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.createdDate = createdDate
        self.currentPlayDuration = currentPlayDuration
        self.totalPlayTime = totalPlayTime
        self.status = status
        self.sortOrder = sortOrder
        self.activatedAtDate = activatedAtDate
    }
}

enum PlayerStatus: String, Codable {
    case active = "active"
    case benched = "benched"
    case temporarilyOut = "temporarilyOut"
}
