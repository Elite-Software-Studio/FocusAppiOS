//
//  InboxView.swift
//  FocusZone
//
//  Quick notes inbox: capture ideas and convert them to tasks for the day.
//

import SwiftUI
import SwiftData

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
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
                    captureCard

                    if notes.isEmpty {
                        emptyState
                    } else {
                        notesSection
                    }
                }
            }
            .navigationTitle(NSLocalizedString("inbox", comment: "Inbox screen title"))
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showTaskForm) {
                TaskFormView(initialTitle: initialTitleForForm)
                    .environment(\.modelContext, modelContext)
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

    // MARK: - Capture card
    private var captureCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.accent)

                VStack(alignment: .leading, spacing: 12) {
                    TextField(NSLocalizedString("quick_note_placeholder", comment: "Quick note input placeholder"), text: $newNoteText, axis: .vertical)
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1...6)
                        .focused($isInputFocused)
                        .submitLabel(.done)
                        .onSubmit { addNote() }

                    HStack {
                        Text(NSLocalizedString("inbox_capture_hint", comment: "Hint under input"))
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)

                        Spacer()

                        Button(action: { addNote() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(NSLocalizedString("add_note", comment: "Add note button"))
                                    .font(AppFonts.subheadline())
                            }
                            .foregroundColor(canAddNote ? .white : AppColors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(canAddNote ? AppColors.accent : AppColors.textSecondary.opacity(0.2))
                            )
                        }
                        .disabled(!canAddNote)
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.card)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    private var canAddNote: Bool {
        !newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppColors.accent.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "tray")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(AppColors.accent)
            }

            VStack(spacing: 8) {
                Text(NSLocalizedString("inbox_empty_title", comment: "Inbox empty state title"))
                    .font(AppFonts.title())
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(NSLocalizedString("inbox_empty_subtitle", comment: "Inbox empty state subtitle"))
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Notes list with section header
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("quick_notes", comment: "Section title for notes list"))
                    .font(AppFonts.subheadline())
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)

                Text("\(notes.count)")
                    .font(AppFonts.caption())
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(AppColors.accent))
            }
            .padding(.horizontal, 20)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(notes, id: \.id) { note in
                        InboxNoteCard(
                            note: note,
                            onConvertToTask: { convertToTask(note) },
                            onDelete: { deleteNote(note) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    private func addNote() {
        guard let ctx = inboxContext else { return }
        let trimmed = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let note = QuickNote(content: trimmed)
        ctx.insert(note)
        newNoteText = ""
        isInputFocused = false
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

// MARK: - Inbox note card (redesigned)
struct InboxNoteCard: View {
    let note: QuickNote
    let onConvertToTask: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.accent)
                .frame(width: 4)
                .padding(.top, 20)
                .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 10) {
                Text(note.content)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text(formattedDate(note.createdAt))
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    HStack(spacing: 12) {
                        Button(action: onConvertToTask) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 14))
                                Text(NSLocalizedString("add_to_timeline", comment: "Convert to task button"))
                                    .font(AppFonts.caption())
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(AppColors.accent)
                        }
                        .buttonStyle(.plain)

                        Button(action: { showDeleteConfirm = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.card)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 1)
        )
        .confirmationDialog(NSLocalizedString("delete_note", comment: "Delete note action"), isPresented: $showDeleteConfirm) {
            Button(NSLocalizedString("delete", comment: "Delete button"), role: .destructive, action: onDelete)
            Button(NSLocalizedString("cancel", comment: "Cancel button"), role: .cancel) {}
        } message: {
            Text(NSLocalizedString("delete_note_confirmation", comment: "Delete note confirmation message"))
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: QuickNote.self, configurations: config)
    return InboxView()
        .environment(\.inboxModelContext, container.mainContext)
}
