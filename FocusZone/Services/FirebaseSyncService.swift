//
//  FirebaseSyncService.swift
//  FocusZone
//
//  Local-first sync: push local SwiftData to Firestore, pull and merge (LWW) when online.
//

import Foundation
import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class FirebaseSyncService: ObservableObject {
    static let shared = FirebaseSyncService()

    @Published private(set) var syncStatus: SyncStatus = .idle
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var errorMessage: String?

    private let auth = FirebaseAuthService.shared
    private let db = Firestore.firestore()

    enum SyncStatus {
        case idle
        case syncing
        case completed
        case failed(String)
    }

    private init() {}

    /// Call when app launches or becomes active. Pull first (merge remote), then push (upload local).
    func sync(taskContext: ModelContext, inboxContext: ModelContext?) async {
        guard auth.isSignedIn, let uid = auth.userId else {
            errorMessage = "Not signed in"
            return
        }

        syncStatus = .syncing
        errorMessage = nil

        do {
            try await pullTasks(uid: uid, context: taskContext)
            try await pullQuickNotes(uid: uid, context: inboxContext)
            try await pushTasks(uid: uid, context: taskContext)
            try await pushQuickNotes(uid: uid, context: inboxContext)

            lastSyncDate = Date()
            syncStatus = .completed
        } catch {
            syncStatus = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Push (local → Firestore)

    private func pushTasks(uid: String, context: ModelContext) async throws {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { $0.statusRawValue != "cancelled" },
            sortBy: [SortDescriptor(\.updatedAt)]
        )
        let tasks = try context.fetch(descriptor)
        let encoder = Firestore.Encoder()

        for task in tasks {
            let dto = taskDTO(from: task)
            let data = try encoder.encode(dto)
            try await db.collection("users").document(uid).collection("tasks").document(dto.id).setData(data)
        }
    }

    private func pushQuickNotes(uid: String, context: ModelContext?) async throws {
        guard let context = context else { return }
        let descriptor = FetchDescriptor<QuickNote>(sortBy: [SortDescriptor(\.createdAt)])
        let notes = try context.fetch(descriptor)
        let encoder = Firestore.Encoder()

        for note in notes {
            let dto = QuickNoteDTO(id: note.id.uuidString, content: note.content, createdAt: note.createdAt)
            let data = try encoder.encode(dto)
            try await db.collection("users").document(uid).collection("quickNotes").document(dto.id).setData(data)
        }
    }

    // MARK: - Pull (Firestore → local, LWW)

    private func pullTasks(uid: String, context: ModelContext) async throws {
        let snapshot = try await db.collection("users").document(uid).collection("tasks").getDocuments()

        for document in snapshot.documents {
            let dto = try document.data(as: TaskDTO.self)
            try mergeTask(dto: dto, context: context)
        }
        try context.save()
    }

    private func pullQuickNotes(uid: String, context: ModelContext?) async throws {
        guard let context = context else { return }
        let snapshot = try await db.collection("users").document(uid).collection("quickNotes").getDocuments()

        for document in snapshot.documents {
            let dto = try document.data(as: QuickNoteDTO.self)
            try mergeQuickNote(dto: dto, context: context)
        }
        try context.save()
    }

    // MARK: - Merge helpers (LWW)

    private func mergeTask(dto: TaskDTO, context: ModelContext) throws {
        guard let id = UUID(uuidString: dto.id) else { return }

        let descriptor = FetchDescriptor<Task>(predicate: #Predicate<Task> { $0.id == id })
        let existing = try context.fetch(descriptor).first

        if let existing = existing, existing.updatedAt >= dto.updatedAt {
            return
        }

        let color = Color(hex: dto.colorHex) ?? .blue
        let parentTaskId: UUID? = dto.parentTaskId.flatMap { UUID(uuidString: $0) }

        if let existing = existing {
            existing.title = dto.title
            existing.icon = dto.icon
            existing.startTime = dto.startTime
            existing.durationMinutes = dto.durationMinutes
            existing.isCompleted = dto.isCompleted
            existing.taskTypeRawValue = dto.taskTypeRawValue
            existing.statusRawValue = dto.statusRawValue
            existing.actualStartTime = dto.actualStartTime
            existing.repeatRuleRawValue = dto.repeatRuleRawValue
            existing.createdAt = dto.createdAt
            existing.updatedAt = dto.updatedAt
            existing.colorHex = dto.colorHex
            existing.parentTaskId = parentTaskId
            existing.isGeneratedFromRepeat = dto.isGeneratedFromRepeat
            if let base64 = dto.focusSettingsDataBase64, let data = Data(base64Encoded: base64) {
                existing.focusSettingsData = data
            }
        } else {
            let task = Task(
                id: id,
                title: dto.title,
                icon: dto.icon,
                startTime: dto.startTime,
                durationMinutes: dto.durationMinutes,
                color: color,
                isCompleted: dto.isCompleted,
                taskType: dto.taskTypeRawValue.flatMap { TaskType(rawValue: $0) },
                status: TaskStatus(rawValue: dto.statusRawValue) ?? .scheduled,
                actualStartTime: dto.actualStartTime,
                repeatRule: RepeatRule(rawValue: dto.repeatRuleRawValue) ?? .none,
                isGeneratedFromRepeat: dto.isGeneratedFromRepeat,
                parentTaskId: parentTaskId
            )
            if let base64 = dto.focusSettingsDataBase64, let data = Data(base64Encoded: base64) {
                task.focusSettingsData = data
            }
            context.insert(task)
        }
    }

    private func mergeQuickNote(dto: QuickNoteDTO, context: ModelContext) throws {
        guard let id = UUID(uuidString: dto.id) else { return }

        let descriptor = FetchDescriptor<QuickNote>(predicate: #Predicate<QuickNote> { $0.id == id })
        let existing = try context.fetch(descriptor).first

        if let existing = existing, existing.createdAt >= dto.createdAt {
            return
        }

        if let existing = existing {
            existing.content = dto.content
            existing.createdAt = dto.createdAt
        } else {
            let note = QuickNote(id: id, content: dto.content, createdAt: dto.createdAt)
            context.insert(note)
        }
    }

    // MARK: - Task → DTO

    private func taskDTO(from task: Task) -> TaskDTO {
        TaskDTO(
            id: task.id.uuidString,
            title: task.title,
            icon: task.icon,
            startTime: task.startTime,
            durationMinutes: task.durationMinutes,
            isCompleted: task.isCompleted,
            taskTypeRawValue: task.taskTypeRawValue,
            statusRawValue: task.statusRawValue,
            actualStartTime: task.actualStartTime,
            repeatRuleRawValue: task.repeatRuleRawValue,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            colorHex: task.colorHex,
            parentTaskId: task.parentTaskId?.uuidString,
            isGeneratedFromRepeat: task.isGeneratedFromRepeat,
            focusSettingsDataBase64: task.focusSettingsData?.base64EncodedString()
        )
    }
}
