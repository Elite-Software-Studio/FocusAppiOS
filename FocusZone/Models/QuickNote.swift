//
//  QuickNote.swift
//  FocusZone
//
//  Inbox item: quick notes that can be converted to tasks later.
//

import Foundation
import SwiftData

@Model
final class QuickNote {
    var id: UUID
    var content: String
    var createdAt: Date

    init(id: UUID = UUID(), content: String, createdAt: Date = Date()) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }
}
