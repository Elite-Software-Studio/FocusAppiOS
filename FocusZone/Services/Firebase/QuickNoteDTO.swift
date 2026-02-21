//
//  QuickNoteDTO.swift
//  FocusZone
//
//  Codable DTO for syncing QuickNote with Firestore.
//

import Foundation

struct QuickNoteDTO: Codable {
    var id: String
    var content: String
    var createdAt: Date
}
