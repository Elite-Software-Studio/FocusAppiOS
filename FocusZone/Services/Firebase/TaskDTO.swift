//
//  TaskDTO.swift
//  FocusZone
//
//  Codable DTO for syncing Task with Firestore. Flat fields only.
//

import Foundation

struct TaskDTO: Codable {
    var id: String
    var title: String
    var icon: String
    var startTime: Date
    var durationMinutes: Int
    var isCompleted: Bool
    var taskTypeRawValue: String?
    var statusRawValue: String
    var actualStartTime: Date?
    var repeatRuleRawValue: String
    var createdAt: Date
    var updatedAt: Date
    var colorHex: String
    var parentTaskId: String?
    var isGeneratedFromRepeat: Bool
    var focusSettingsDataBase64: String?

    enum CodingKeys: String, CodingKey {
        case id, title, icon, startTime, durationMinutes, isCompleted
        case taskTypeRawValue, statusRawValue, actualStartTime, repeatRuleRawValue
        case createdAt, updatedAt, colorHex, parentTaskId, isGeneratedFromRepeat
        case focusSettingsDataBase64
    }
}
