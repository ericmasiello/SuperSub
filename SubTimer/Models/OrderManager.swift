//
//  OrderManager.swift
//  SubTimer
//
//  Created by SubTimer on 7/29/26.
//

import Foundation
import SwiftData

enum PlayerOrderRole: String, Codable {
    case bench = "bench"
    case active = "active"
}

@Model
final class OrderManager {
    static let defaultPlayerOrder: [UUID] = []

    var id = UUID()
    var role = PlayerOrderRole.bench
    var playerOrder = OrderManager.defaultPlayerOrder
    var createdDate = Date()
    var updatedDate = Date()

    init(
        role: PlayerOrderRole,
        id: UUID = UUID(),
        playerOrder: [UUID] = OrderManager.defaultPlayerOrder,
        createdDate: Date = Date(),
        updatedDate: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.playerOrder = playerOrder
        self.createdDate = createdDate
        self.updatedDate = updatedDate
    }

    // MARK: - Order Management

    /// Adds a player to the end of the order
    func addPlayer(_ playerId: UUID) {
        guard !playerOrder.contains(playerId) else { return }
        playerOrder.append(playerId)
        updatedDate = Date()
    }

    /// Inserts a player at a specific position in the order
    func insertPlayer(_ playerId: UUID, at index: Int) {
        guard !playerOrder.contains(playerId) else { return }
        let safeIndex = min(max(0, index), playerOrder.count)
        playerOrder.insert(playerId, at: safeIndex)
        updatedDate = Date()
    }

    /// Removes a player from the order
    func removePlayer(_ playerId: UUID) {
        playerOrder.removeAll { $0 == playerId }
        updatedDate = Date()
    }

    /// Moves a player to a specific position in the order
    func movePlayer(_ playerId: UUID, to index: Int) {
        guard let currentIndex = playerOrder.firstIndex(of: playerId) else { return }
        playerOrder.remove(at: currentIndex)
        let safeIndex = min(max(0, index), playerOrder.count)
        playerOrder.insert(playerId, at: safeIndex)
        updatedDate = Date()
    }

    /// Gets the position of a player in the order (0-indexed)
    func position(of playerId: UUID) -> Int? {
        return playerOrder.firstIndex(of: playerId)
    }

    /// Returns the player ID at the front of the order (next up)
    var nextPlayer: UUID? {
        return playerOrder.first
    }

    /// Clears all players from the order
    func clear() {
        playerOrder.removeAll()
        updatedDate = Date()
    }

    /// Returns the number of players in the order
    var count: Int {
        return playerOrder.count
    }

    /// Returns whether the order has no players
    var isEmpty: Bool {
        return playerOrder.isEmpty
    }
}
