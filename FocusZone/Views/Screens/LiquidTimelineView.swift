import SwiftUI
import SwiftData

struct LiquidTimelineView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = TimelineViewModel()
    @ObservedObject private var timerService = TaskTimerService.shared
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date = Date()
    @State private var showAddTaskForm = false
    @State private var editingTask: Task?
    @State private var selectedTaskForActions: Task?
    @State private var showNotificationAlert = false
    @State private var showProGate = false
    @State private var showPaywall = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid mesh background
                LiquidDesignSystem.Gradients.meshBackground(colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: LiquidDesignSystem.Spacing.lg) {
                    // Notification permission banner
                    if !notificationService.isAuthorized {
                        notificationPermissionBanner
                            .padding(.horizontal, LiquidDesignSystem.Spacing.md)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Date Header - Fixed at top
                    WeekDateNavigator(
                        selectedDate: $selectedDate
                    )
                    .padding(.horizontal, LiquidDesignSystem.Spacing.md)
                    
                    // Main Content Area
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: LiquidDesignSystem.Spacing.md) {
                                if viewModel.tasks.isEmpty {
                                    // Empty state with liquid design
                                    emptyStateView
                                        .padding(.top, LiquidDesignSystem.Spacing.xxl)
                                } else {
                                    ForEach(Array(viewModel.tasks.enumerated()), id: \.element.id) { index, task in
                                        LiquidTaskCard(
                                            title: task.title,
                                            time: viewModel.timeRange(for: task),
                                            icon: task.icon,
                                            color: viewModel.taskColor(task),
                                            isCompleted: task.isCompleted,
                                            durationMinutes: task.durationMinutes,
                                            task: task,
                                            timelineViewModel: viewModel
                                        )
                                        .onTapGesture {
                                            withAnimation(LiquidDesignSystem.Animation.smooth) {
                                                selectedTaskForActions = task
                                            }
                                        }
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                        
                                        // Show break suggestions after this task
                                        ForEach(viewModel.breakSuggestions.filter { $0.insertAfterTaskId == task.id }) { suggestion in
                                            LiquidBreakSuggestionCard(
                                                suggestion: suggestion,
                                                onAccept: {
                                                    withAnimation(LiquidDesignSystem.Animation.smooth) {
                                                        viewModel.acceptBreakSuggestion(suggestion)
                                                    }
                                                },
                                                onDismiss: {
                                                    withAnimation(LiquidDesignSystem.Animation.smooth) {
                                                        viewModel.dismissBreakSuggestion(suggestion)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                    
                                    // Add standalone suggestions after all tasks
                                    ForEach(viewModel.breakSuggestions.filter { $0.insertAfterTaskId == nil }) { suggestion in
                                        LiquidBreakSuggestionCard(
                                            suggestion: suggestion,
                                            onAccept: {
                                                withAnimation(LiquidDesignSystem.Animation.smooth) {
                                                    viewModel.acceptBreakSuggestion(suggestion)
                                                }
                                            },
                                            onDismiss: {
                                                withAnimation(LiquidDesignSystem.Animation.smooth) {
                                                    viewModel.dismissBreakSuggestion(suggestion)
                                                }
                                            }
                                        )
                                    }
                                }
                                
                                // Bottom padding to prevent content from hiding behind FAB
                                Spacer()
                                    .frame(height: 100)
                            }
                            .padding(.horizontal, LiquidDesignSystem.Spacing.md)
                        }
                        .refreshable {
                            await withAnimation(LiquidDesignSystem.Animation.smooth) {
                                viewModel.forceRefreshTasks(for: selectedDate)
                            }
                        }
                    }
                }
                
                // Liquid Floating Action Button - Fixed position
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        LiquidFloatingActionButton {
                            handleAddTaskButtonTap()
                        }
                        .padding(.trailing, LiquidDesignSystem.Spacing.lg)
                        .padding(.bottom, LiquidDesignSystem.Spacing.lg)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupViewModels()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.forceRefreshTasks(for: selectedDate)
        }
        .onChange(of: selectedDate) { _, newDate in
            withAnimation(LiquidDesignSystem.Animation.smooth) {
                viewModel.loadTodayTasks(for: newDate)
                viewModel.refreshTasksWithBreakSuggestions(for: newDate)
            }
        }
        .sheet(isPresented: $showAddTaskForm, onDismiss: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.forceRefreshTasks(for: selectedDate)
                viewModel.updateBreakSuggestions()
            }
        }) {
            TaskFormView()
                .environment(\.modelContext, modelContext)
        }
        .sheet(isPresented: Binding<Bool>(
            get: { editingTask != nil },
            set: { if !$0 {
                editingTask = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.forceRefreshTasks(for: selectedDate)
                    viewModel.updateBreakSuggestions()
                }
            } }
        )) {
            if let task = editingTask {
                TaskFormView(taskToEdit: task)
                    .environment(\.modelContext, modelContext)
            }
        }
        .sheet(isPresented: $showProGate) {
            ProGate(
                onUpgrade: {
                    showProGate = false
                    showPaywall = true
                },
                onDismiss: {
                    showProGate = false
                },
                currentTaskCount: viewModel.getCurrentTaskCount(),
                maxTasks: ProFeatures.maxTasksForFree
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: Binding<Bool>(
            get: { selectedTaskForActions != nil },
            set: { if !$0 { selectedTaskForActions = nil } }
        )) {
            if let task = selectedTaskForActions {
                TaskActionsModal(
                    task: task,
                    onStart: { startTask(task) },
                    onComplete: { completeTask(task) },
                    onEdit: { editTask(task) },
                    onDuplicate: { duplicateTask(task) },
                    onDelete: { deletionType in
                        handleTaskDeletion(task, type: deletionType)
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .alert(NSLocalizedString("enable_notifications", comment: "Enable notifications alert title"), isPresented: $showNotificationAlert) {
            Button(NSLocalizedString("enable", comment: "Enable button text")) {
                Task {
                    await viewModel.requestNotificationPermission()
                }
            }
            Button(NSLocalizedString("later", comment: "Later button text"), role: .cancel) { }
        } message: {
            Text(NSLocalizedString("enable_notifications_message", comment: "Enable notifications message"))
        }
    }
    
    // MARK: - Notification Banner
    
    private var notificationPermissionBanner: some View {
        HStack(spacing: LiquidDesignSystem.Spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(LiquidDesignSystem.Colors.warning.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "bell.slash.fill")
                    .font(.title3)
                    .foregroundColor(LiquidDesignSystem.Colors.warning)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.xxs) {
                Text(NSLocalizedString("notifications_disabled_banner", comment: "Notifications disabled banner title"))
                    .font(LiquidDesignSystem.Typography.titleSmall)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextPrimary(colorScheme))
                
                Text(NSLocalizedString("enable_to_get_task_reminders", comment: "Enable to get task reminders"))
                    .font(LiquidDesignSystem.Typography.labelSmall)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextSecondary(colorScheme))
            }
            
            Spacer()
            
            // Enable button
            Button(NSLocalizedString("enable", comment: "Enable button text")) {
                showNotificationAlert = true
            }
            .liquidButton(size: .small, variant: .secondary)
        }
        .glassSurface(
            cornerRadius: LiquidDesignSystem.CornerRadius.lg,
            padding: LiquidDesignSystem.Spacing.md
        )
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: LiquidDesignSystem.Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                LiquidDesignSystem.Colors.primary.opacity(0.1),
                                LiquidDesignSystem.Colors.primary.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(LiquidDesignSystem.Colors.primary)
            }
            
            // Text
            VStack(spacing: LiquidDesignSystem.Spacing.xs) {
                Text(NSLocalizedString("no_tasks_for_today", comment: "No tasks message"))
                    .font(LiquidDesignSystem.Typography.headlineSmall)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextPrimary(colorScheme))
                
                Text(NSLocalizedString("tap_plus_to_create_first_task", comment: "Instruction to create first task"))
                    .font(LiquidDesignSystem.Typography.bodyMedium)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextSecondary(colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(LiquidDesignSystem.Spacing.xxl)
    }
    
    // MARK: - Helper Methods
    
    private func handleTaskDeletion(_ task: Task, type: TaskActionsModal.DeletionType) {
        withAnimation(LiquidDesignSystem.Animation.smooth) {
            switch type {
            case .instance:
                viewModel.deleteTaskInstance(task)
            case .allInstances:
                viewModel.deleteAllTaskInstances(task)
            case .futureInstances:
                viewModel.deleteFutureTaskInstances(task)
            }
        }
        selectedTaskForActions = nil
    }
        
    private func setupViewModels() {
        viewModel.setModelContext(modelContext)
        timerService.setModelContext(modelContext)
        viewModel.loadTodayTasks(for: selectedDate)
        viewModel.refreshTasksWithBreakSuggestions(for: selectedDate)
        
        // Show notification permission alert if not authorized
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if !notificationService.isAuthorized {
                showNotificationAlert = true
            }
        }
    }
    
    // MARK: - Task Actions
    
    private func deleteTask(_ task: Task) {
        withAnimation(LiquidDesignSystem.Animation.smooth) {
            viewModel.deleteTask(task)
        }
        selectedTaskForActions = nil
    }
    
    private func duplicateTask(_ task: Task) {
        viewModel.duplicateTask(task)
        selectedTaskForActions = nil
    }
    
    private func completeTask(_ task: Task) {
        withAnimation(LiquidDesignSystem.Animation.smooth) {
            viewModel.completeTask(task)
        }
        selectedTaskForActions = nil
    }
    
    private func editTask(_ task: Task) {
        selectedTaskForActions = nil
        editingTask = task
    }
    
    private func startTask(_ task: Task) {
        timerService.startTask(task)
        selectedTaskForActions = nil
    }
    
    private func handleAddTaskButtonTap() {
        if subscriptionManager.isProUser {
            showAddTaskForm = true
        } else {
            if viewModel.canCreateNewTask() {
                showAddTaskForm = true
            } else {
                showProGate = true
            }
        }
    }
}

// MARK: - Liquid Break Suggestion Card

struct LiquidBreakSuggestionCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    let suggestion: BreakSuggestion
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: LiquidDesignSystem.Spacing.md) {
            // Icon
            Text(suggestion.icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(LiquidDesignSystem.Colors.info.opacity(0.15))
                )
            
            // Content
            VStack(alignment: .leading, spacing: LiquidDesignSystem.Spacing.xxs) {
                Text(suggestion.reason)
                    .font(LiquidDesignSystem.Typography.titleSmall)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextPrimary(colorScheme))
                
                Text("\(suggestion.suggestedDuration) min break")
                    .font(LiquidDesignSystem.Typography.labelSmall)
                    .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextSecondary(colorScheme))
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: LiquidDesignSystem.Spacing.xs) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(LiquidDesignSystem.Colors.adaptiveTextTertiary(colorScheme))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(LiquidDesignSystem.Colors.adaptiveSurfaceSecondary(colorScheme))
                        )
                }
                
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(LiquidDesignSystem.Gradients.primaryGradient)
                        )
                }
            }
        }
        .padding(LiquidDesignSystem.Spacing.md)
        .glassSurface(
            cornerRadius: LiquidDesignSystem.CornerRadius.lg,
            padding: 0
        )
    }
}

// MARK: - Preview

#Preview {
    LiquidTimelineView()
        .environmentObject(ThemeManager())
        .environmentObject(NotificationService.shared)
}

