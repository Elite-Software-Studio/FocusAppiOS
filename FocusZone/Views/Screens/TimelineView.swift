import SwiftUI
import SwiftData

// Create an alias to avoid conflict with Swift's Task
typealias FocusTask = Task

struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()
    @ObservedObject private var timerService = TaskTimerService.shared
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date = Date()
    @State private var showAddTaskForm = false
    @State private var editingTask: FocusTask?
    @State private var selectedTaskForActions: FocusTask?
    @State private var showNotificationAlert = false
    @State private var showProGate = false
    @State private var showPaywall = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Notification permission banner
                    if !notificationService.isAuthorized {
                        notificationPermissionBanner
                    }
                    
                    // Date Header - Fixed at top
                    WeekDateNavigator(
                        selectedDate: $selectedDate
                    )
                    
                    // Main Content Area
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                if viewModel.tasks.isEmpty {
                                    // Empty state
                                    VStack(spacing: 16) {
                                        Image(systemName: "calendar.badge.plus")
                                            .font(.system(size: 48))
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        Text(NSLocalizedString("no_tasks_for_today", comment: "No tasks message"))
                                            .font(AppFonts.headline())
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        Text(NSLocalizedString("tap_plus_to_create_first_task", comment: "Instruction to create first task"))
                                            .font(AppFonts.body())
                                            .foregroundColor(AppColors.textSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.top, 10)
                                } else {
                                    ForEach(Array(viewModel.tasks.enumerated()), id: \.element.id) { index, task in
                                        TaskCard(
                                            title: task.title,
                                            time: viewModel.timeRange(for: task),
                                            icon: task.icon,
                                            color: viewModel.taskColor(task),
                                            isCompleted: task.isCompleted,
                                            durationMinutes: task.durationMinutes,
                                            task: task,
                                            timelineViewModel: viewModel
                                        )
//                                        .padding(.horizontal, 16)
//                                        .padding(.vertical, 8)
                                        .onTapGesture {
                                            selectedTaskForActions = task
                                        }
                                        
                                        // Show break suggestions after this task
                                        ForEach(viewModel.breakSuggestions.filter { $0.insertAfterTaskId == task.id }) { suggestion in
                                            BreakSuggestionCard(
                                                suggestion: suggestion,
                                                onAccept: {
                                                    viewModel.acceptBreakSuggestion(suggestion)
                                                },
                                                onDismiss: {
                                                    viewModel.dismissBreakSuggestion(suggestion)
                                                }
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 4)
                                        }
                                    }
                                    
                                    // Add standalone suggestions after all tasks
                                    ForEach(viewModel.breakSuggestions.filter { $0.insertAfterTaskId == nil }) { suggestion in
                                        BreakSuggestionCard(
                                            suggestion: suggestion,
                                            onAccept: {
                                                viewModel.acceptBreakSuggestion(suggestion)
                                            },
                                            onDismiss: {
                                                viewModel.dismissBreakSuggestion(suggestion)
                                            }
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 4)
                                    }
                                    
                                    // And add this to the onChange modifier for selectedDate:
                                    .onChange(of: selectedDate) { _, newDate in
                                        viewModel.loadTodayTasks(for: newDate)
                                        viewModel.updateBreakSuggestions() // Add this line
                                    }
                                    
                                }
                                
                                // Bottom padding to prevent content from hiding behind FAB
                                Spacer()
                                    .frame(height: 100)
                            }
                        }
                        .refreshable {
                            viewModel.forceRefreshTasks(for: selectedDate)
                        }
                        .padding(.horizontal, 16)
//                        .padding(.vertical, 26)
                    }
                }
                
                // Floating Action Button - Fixed position
                // VStack {
                //     Spacer()
                //     
                //     HStack {
                //         Spacer()
                //         
                //         FloatingActionButton {
                //             handleAddTaskButtonTap()
                //         }
                //         .padding(.trailing, 20)
                //         .padding(.bottom, 20)
                //     }
                // }
            }
            

        }
        .navigationBarHidden(true)
        .onAppear {
            setupViewModels()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Refresh timeline when app becomes active
            viewModel.forceRefreshTasks(for: selectedDate)
            print("TimelineView: Refreshed on app becoming active")
        }
        .onChange(of: selectedDate) { _, newDate in
            viewModel.loadTodayTasks(for: newDate)
            viewModel.refreshTasksWithBreakSuggestions(for: newDate)
            
        }
        .sheet(isPresented: $showAddTaskForm, onDismiss: {
            // Refresh timeline after creating a task with a small delay to ensure data is saved
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.forceRefreshTasks(for: selectedDate)
                viewModel.updateBreakSuggestions()
                print("TimelineView: Force refreshed after task creation")
            }
        }) {
            TaskFormView()
                .environment(\.modelContext, modelContext)
        }
        .sheet(isPresented: Binding<Bool>(
            get: { editingTask != nil },
            set: { if !$0 {
                editingTask = nil
                // Refresh timeline after editing a task
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.forceRefreshTasks(for: selectedDate)
                    viewModel.updateBreakSuggestions()
                    print("TimelineView: Force refreshed after task edit")
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
                _Concurrency.Task {
                    await viewModel.requestNotificationPermission()
                }
            }
            Button(NSLocalizedString("later", comment: "Later button text"), role: .cancel) { }
        } message: {
            Text(NSLocalizedString("enable_notifications_message", comment: "Enable notifications message"))
        }
    }
    
    private var notificationPermissionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("notifications_disabled_banner", comment: "Notifications disabled banner title"))
                    .font(AppFonts.subheadline())
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(NSLocalizedString("enable_to_get_task_reminders", comment: "Enable to get task reminders"))
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Button(NSLocalizedString("enable", comment: "Enable button text")) {
                showNotificationAlert = true
            }
            .font(AppFonts.caption())
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.accent)
            .cornerRadius(16)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.orange.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    
    private func handleTaskDeletion(_ task: FocusTask, type: TaskActionsModal.DeletionType) {
        withAnimation(.easeInOut(duration: 0.3)) {
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
        viewModel.refreshTasksWithBreakSuggestions(for: selectedDate) // Changed this line
        
        // Show notification permission alert if not authorized
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if !notificationService.isAuthorized {
                showNotificationAlert = true
            }
        }
    }
    
    // MARK: - Task Actions
    private func deleteTask(_ task: FocusTask) {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.deleteTask(task)
        }
        selectedTaskForActions = nil
    }
    
    private func duplicateTask(_ task: FocusTask) {
        viewModel.duplicateTask(task)
        selectedTaskForActions = nil
    }
    
    private func completeTask(_ task: FocusTask) {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.completeTask(task)
        }
        selectedTaskForActions = nil
    }
    
    private func editTask(_ task: FocusTask) {
        selectedTaskForActions = nil
        editingTask = task
    }
    
    private func startTask(_ task: FocusTask) {
        timerService.startTask(task)
        selectedTaskForActions = nil
    }
    
    private func handleAddTaskButtonTap() {
        if subscriptionManager.isProUser {
            // Pro users can always add tasks
            showAddTaskForm = true
        } else {
            // Check if user can add more tasks
            if viewModel.canCreateNewTask() {
                showAddTaskForm = true
            } else {
                // Show pro gate
                showProGate = true
            }
        }
    }
}

struct FloatingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.9),
                            Color.blue.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: isPressed ? 4 : 8,
                    x: 0,
                    y: isPressed ? 2 : 4
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 50) {
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
}



// MARK: - Sample Data
let _sampleTasks: [Task] = [
    Task(
        id: UUID(),
        title: "Rise and Shine",
        icon: "🌅",
        startTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
        durationMinutes: 45,
        color: .pink,
        isCompleted: true
    ),
    Task(
        id: UUID(),
        title: "Keep working",
        icon: "💼",
        startTime: Calendar.current.date(bySettingHour: 16, minute: 11, second: 0, of: Date()) ?? Date(),
        durationMinutes: 120, // 2h 30min
        color: .green,
        isCompleted: false
    ),
    Task(
        id: UUID(),
        title: "Go for a Run!",
        icon: "🏃‍♂️",
        startTime: Calendar.current.date(bySettingHour: 19, minute: 15, second: 0, of: Date()) ?? Date(),
        durationMinutes: 90, // 1h 30min
        color: .orange,
        isCompleted: false
    ),
    
    Task(
        id: UUID(),
        title: "Go for a Run!",
        icon: "🏃‍♂️",
        startTime: Calendar.current.date(bySettingHour: 19, minute: 35, second: 0, of: Date()) ?? Date(),
        durationMinutes: 60, // 1h 30min
        color: .orange,
        isCompleted: false
    ),
    Task(
        id: UUID(),
        title: "Wind Down",
        icon: "🌙",
        startTime: Calendar.current.date(bySettingHour: 15, minute: 00, second: 0, of: Date()) ?? Date(),
        durationMinutes: 45,
        color: .blue,
        isCompleted: false
    )
]

// MARK: - Timeline View Container
struct TimelineViewPreview: View {
    @State private var selectedDate = Date()
    @State private var tasks: [Task] = _sampleTasks
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Date Header
                WeekDateNavigator(selectedDate: $selectedDate)
            
                // Timeline
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks) { task in
                            TaskCard(
                                title: task.title,
                                time: "",
                                icon: task.icon,
                                color: task.color,
                                isCompleted: task.isCompleted,
                                durationMinutes: task.durationMinutes,
                                task: task,
                                timelineViewModel: nil
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                
                }
            }
        }
    }
}

#Preview {
    TimelineViewPreview()
        .environmentObject(ThemeManager())
        .environmentObject(NotificationService.shared)
}
