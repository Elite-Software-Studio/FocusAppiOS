# FocusZone

FocusZone is a productivity application designed to help users manage their tasks effectively. It provides features such as task timers, notifications, AI assistance, and customizable task settings.

## Features

-   **Task Management**: Create, edit, and organize tasks with various attributes like duration, color, and type.
-   **Task Timer**: Start, pause, resume, and complete tasks with real-time tracking.
-   **AI Assistance**: Get suggestions and insights for better task management.
-   **Customizable Themes**: Personalize the app with different colors and fonts.
-   **Notifications**: Receive reminders and updates for your tasks.

## Project Structure

```
FocusZone/
├── App/
│   ├── FocusZoneApp.swift
│   ├── ThemeManager.swift
├── Assets.xcassets/
├── Helpers/
│   ├── Utils.swift
│   ├── Extensions/
│   │   ├── Color+Ext.swift
│   │   ├── Date+Ext.swift
│   │   ├── View+Ext.swift
├── Models/
│   ├── RepeatRule.swift
│   ├── Task.swift
│   ├── TaskType.swift
├── Services/
│   ├── AIService.swift
│   ├── NotificationService.swift
│   ├── TaskRepository.swift
│   ├── TaskTimerService.swift
├── ViewModels/
│   ├── AIAssistantViewModel.swift
│   ├── TaskViewModel.swift
│   ├── TimelineViewModel.swift
├── Views/
│   ├── Components/
│   │   ├── AlertBox.swift
│   │   ├── AppButton.swift
│   │   ├── AppModal.swift
│   │   ├── AppPicker.swift
│   │   ├── AppTextField.swift
│   │   ├── AppToggle.swift
│   │   ├── DateHeader.swift
│   │   ├── DateSelector.swift
│   │   ├── MainTabView.swift
│   │   ├── TaskTimer.swift
│   │   ├── ItemList/
│   │   │   ├── TaskCard.swift
│   │   ├── Modal/
│   │   │   ├── TaskActionsModal.swift
│   │   ├── TaskForm/
│   │   │   ├── TaskAlertsSection.swift
│   │   │   ├── TaskColorPicker.swift
│   │   │   ├── TaskDetailsSection.swift
│   │   │   ├── TaskDurationSelector.swift
│   │   │   ├── TaskFormHeader.swift
│   │   │   ├── TaskIconPicker.swift
│   │   │   ├── TaskPreviewGrid.swift
│   │   │   ├── TaskRepeatSelector.swift
│   │   │   ├── TaskTimeSelector.swift
│   │   │   ├── TaskTitleInput.swift
│   ├── Screens/
│   │   ├── AIAssistantView.swift
│   │   ├── SettingsView.swift
│   │   ├── SplashScreen.swift
│   │   ├── TaskFormView.swift
│   │   ├── TaskTimerView.swift
│   │   ├── TimelineView.swift
├── Resources/
│   ├── AppColors.swift
│   ├── AppFonts.swift
│   ├── Localizable.strings
│   ├── Font/
│   │   ├── Montserrat-Regular.ttf
├── FocusZone.xcodeproj/
│   ├── project.pbxproj
│   ├── project.xcworkspace/
│   │   ├── contents.xcworkspacedata
│   │   ├── xcshareddata/
│   │   │   ├── swiftpm/
│   │   │   │   ├── configuration/
│   │   ├── xcuserdata/
│   │   │   ├── julio.xcuserdatad/
│   │   │   │   ├── UserInterfaceState.xcuserstate
│   │   │   │   ├── xcdebugger/
│   │   │   │   │   ├── Breakpoints_v2.xcbkptlist
│   │   │   │   ├── xcschemes/
│   │   │   │   │   ├── xcschememanagement.plist
```

## Requirements

-   Xcode 14 or later
-   Swift 5.8 or later
-   iOS 16.0 or later

## Installation

1. Clone the repository:
    ```bash
    git clone https://github.com/yourusername/FocusZone.git
    ```
2. Open the project in Xcode:
    ```bash
    open FocusZone.xcodeproj
    ```
3. Build and run the project on a simulator or device.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Commit your changes and push them to your fork.
4. Submit a pull request.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contact

For any inquiries or support, please contact [your email address].
