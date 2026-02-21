//
//  InboxView.swift
//  FocusZone
//
//  Quick notes inbox: capture ideas and convert them to tasks for the day.
//

import SwiftUI
import SwiftData

struct InboxView: View {
    @Environment(\.inboxModelContext) private var inboxContext

    @State private var notes: [QuickNote] = []
    @State private var newNoteText: String = ""
    @State private var showTaskForm: Bool = false
    @State private var initialTitleForForm: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    addNoteSection

                    if notes.isEmpty {
                        emptyState
                    } else {
                        notesList
                    }
                }
            }
            .navigationTitle(NSLocalizedString("inbox", comment: "Inbox screen title"))
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showTaskForm) {
                TaskFormView(initialTitle: initialTitleForForm)
            }
            .onAppear { fetchNotes() }
            .onChange(of: showTaskForm) { _, isShowing in
                if !isShowing { fetchNotes() }
            }
        }
    }

    private func fetchNotes() {
        guard let ctx = inboxContext else { return }
        let descriptor = FetchDescriptor<QuickNote>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        do {
            notes = try ctx.fetch(descriptor)
        } catch {
            print("InboxView: Failed to fetch notes: \(error)")
        }
    }

    private var addNoteSection: some View {
        HStack(spacing: 12) {
            TextField(NSLocalizedString("quick_note_placeholder", comment: "Quick note input placeholder"), text: $newNoteText)
                .font(AppFonts.body())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.card)
                .foregroundColor(AppColors.textPrimary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.textSecondary.opacity(0.3), lineWidth: 1)
                )
                .focused($isInputFocused)
                .submitLabel(.done)
                .onSubmit { addNote() }

            Button(action: { addNote() }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.accent)
            }
            .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.background)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)

            Text(NSLocalizedString("inbox_empty_title", comment: "Inbox empty state title"))
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Text(NSLocalizedString("inbox_empty_subtitle", comment: "Inbox empty state subtitle"))
                .font(AppFonts.body())
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(notes, id: \.id) { note in
                    InboxNoteRow(
                        note: note,
                        onConvertToTask: { convertToTask(note) },
                        onDelete: { deleteNote(note) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func addNote() {
        guard let ctx = inboxContext else { return }
        let trimmed = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let note = QuickNote(content: trimmed)
        ctx.insert(note)
        newNoteText = ""
        do {
            try ctx.save()
            fetchNotes()
        } catch {
            print("InboxView: Failed to save note: \(error)")
        }
    }

    private func convertToTask(_ note: QuickNote) {
        guard let ctx = inboxContext else { return }
        initialTitleForForm = note.content
        ctx.delete(note)
        do {
            try ctx.save()
            fetchNotes()
        } catch {
            print("InboxView: Failed to delete note after convert: \(error)")
        }
        showTaskForm = true
    }

    private func deleteNote(_ note: QuickNote) {
        guard let ctx = inboxContext else { return }
        ctx.delete(note)
        do {
            try ctx.save()
            fetchNotes()
        } catch {
            print("InboxView: Failed to delete note: \(error)")
        }
    }
}

// MARK: - Inbox note row
struct InboxNoteRow: View {
    let note: QuickNote
    let onConvertToTask: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.content)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)

                Text(note.createdAt, style: .relative)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(AppColors.card)
            .cornerRadius(12)

            VStack(spacing: 8) {
                Button(action: onConvertToTask) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.accent)
                }
                .buttonStyle(.plain)

                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.danger)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .confirmationDialog(NSLocalizedString("delete_note", comment: "Delete note action"), isPresented: $showDeleteConfirm) {
            Button(NSLocalizedString("delete", comment: "Delete button"), role: .destructive, action: onDelete)
            Button(NSLocalizedString("cancel", comment: "Cancel button"), role: .cancel) {}
        } message: {
            Text(NSLocalizedString("delete_note_confirmation", comment: "Delete note confirmation message"))
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: QuickNote.self, configurations: config)
    return InboxView()
        .environment(\.inboxModelContext, container.mainContext)
}
