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
    var id: UUID
    var name: String
    var createdDate: Date
    var currentPlayDuration: TimeInterval
    var totalPlayTime: TimeInterval
    var status: PlayerStatus
    var sortOrder: Int
    var activatedAtDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        createdDate: Date = Date(),
        currentPlayDuration: TimeInterval = 0,
        totalPlayTime: TimeInterval = 0,
        status: PlayerStatus = .benched,
        sortOrder: Int = 0,
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
    case active
    case benched
    case temporarilyOut
}
