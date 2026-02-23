//
//  BenchManager.swift
//  SubTimer
//
//  Created by SubTimer on 2/13/26.
//

import Foundation
import SwiftData

@Model
final class BenchManager {
    var id: UUID
    var playerOrder: [UUID]
    var createdDate: Date
    var updatedDate: Date

    init(
        id: UUID = UUID(),
        playerOrder: [UUID] = [],
        createdDate: Date = Date(),
        updatedDate: Date = Date()
    ) {
        self.id = id
        self.playerOrder = playerOrder
        self.createdDate = createdDate
        self.updatedDate = updatedDate
    }

    // MARK: - Bench Order Management

    /// Adds a player to the end of the bench
    func addPlayer(_ playerId: UUID) {
        guard !playerOrder.contains(playerId) else { return }
        playerOrder.append(playerId)
        updatedDate = Date()
    }

    /// Inserts a player at a specific position in the bench order
    func insertPlayer(_ playerId: UUID, at index: Int) {
        guard !playerOrder.contains(playerId) else { return }
        let safeIndex = min(max(0, index), playerOrder.count)
        playerOrder.insert(playerId, at: safeIndex)
        updatedDate = Date()
    }

    /// Removes a player from the bench
    func removePlayer(_ playerId: UUID) {
        playerOrder.removeAll { $0 == playerId }
        updatedDate = Date()
    }

    /// Moves a player to a specific position in the bench order
    func movePlayer(_ playerId: UUID, to index: Int) {
        guard let currentIndex = playerOrder.firstIndex(of: playerId) else { return }
        playerOrder.remove(at: currentIndex)
        let safeIndex = min(max(0, index), playerOrder.count)
        playerOrder.insert(playerId, at: safeIndex)
        updatedDate = Date()
    }

    /// Gets the position of a player in the bench order (0-indexed)
    func position(of playerId: UUID) -> Int? {
        return playerOrder.firstIndex(of: playerId)
    }

    /// Returns the player ID at the front of the bench (next to play)
    var nextPlayer: UUID? {
        return playerOrder.first
    }

    /// Clears all players from the bench
    func clear() {
        playerOrder.removeAll()
        updatedDate = Date()
    }

    /// Returns the number of players on the bench
    var count: Int {
        return playerOrder.count
    }
}
