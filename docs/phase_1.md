# Phase 1: Basic Journaling App with Notifications

**[Home](../README.md) | [Next: Phase 2](./phase_2.md)**

---

## Problem Statement
Users need a simple way to journal daily with minimal friction. The app should send notifications to remind users to journal and provide a basic interface for recording entries.

## Solution Overview
In this phase, we implement:
- Scheduled notifications reminding the user to journal.
- A simple UI to display prompts.
- Voice recording and transcription using Apple's built-in speech-to-text API.
- Local storage of transcribed journal entries (not yet sent to Notion).

---

## Feature List
### To implement in this phase:
- **Notifications**: Sent at 8 AM, then every 30 minutes if the user hasn't journaled.
- **UI**: Basic screen displaying the current prompt.
- **Speech-to-Text**: Automatic transcription when the user speaks.
- **Local Storage**: Responses saved locally in memory
- **Journaling Flow**:
  - User opens the app and sees a prompt.
  - User taps a button to start recording.
  - Speech is transcribed and displayed on the screen.
  - User can save or discard the response.
  - App cycles through prompts in a fixed order (Desire → Gratitude → Brag).

### To Be Implemented in Future Phases
- Auto-start recording when the app opens (Phase 2).
- Notion API integration (Phase 3).
- AI-powered prompt switching (Phase 4).
- Persistent reminders with tracking (Phase 5).

## UI & Styling Guidelines
- **Color Palette:**  
  - Background: #FFFFFF (white)  
  - Primary Accent: #007AFF (iOS blue)  
  - Text: #333333 (dark gray)  
- **Typography:**  
  - Font: San Francisco (iOS default)  
  - Headings: Bold, 20pt; Body: Regular, 16pt.
- **Layout:**  
  - Clean, minimal design with plenty of white space.
  - Use rounded corners for buttons and cards.
- **Visuals:**  
  - Use simple icons (e.g., microphone icon for recording) from SF Symbols.
  - Animations for transitions (fade in/out) for a smooth user experience.

## Design Patterns & Architecture
- **MVC (Model-View-Controller):**  
  Organize the code by separating the UI (View), business logic (Controller), and data (Model).  
- **Singleton Pattern:**  
  Create a `NotificationManager` as a singleton to manage scheduling and cancellation of reminders.
- **Observer Pattern:**  
  Use notification observers to update the UI when local data changes (e.g., a new transcription is available).

## Flow Diagrams

### **Sequence Diagram**
See [Phase 1 Sequence Diagram](./diagrams/phase_1_sequence_diagram.md)

### **Flow Diagram**
See [Phase 1 Flow Diagram](./diagrams/phase_1_flow_diagram.md)

## Implementation Checklist
- [x] **Project Setup:**  
  - [x] Create a new Xcode project (Swift, iOS).
  - [x] Configure Info.plist with permissions: `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`, and `NSUserNotificationUsageDescription`.

- [x] **UI Development:**  
  - [x] Create a basic storyboard or SwiftUI view with:
    - A large label for the prompt (e.g., "What do you desire?").
    - A recording button with a microphone icon.
    - A text view area to display the transcription.
  - [x] Apply the style guide (colors, fonts, rounded corners).

- [x] **Notification Scheduling:**  
  - [x] Implement a singleton `NotificationManager`:
    ```swift
    class NotificationManager {
        static let shared = NotificationManager()
        private init() {}
        
        func scheduleMorningNotification() {
            let center = UNUserNotificationCenter.current()
            // Request permissions and schedule a notification at 8 AM and every 30 minutes until 10 PM.
            // (Code for scheduling notifications)
        }
    }
    ```
    A code Example for scheduling a Local Notification:
    ```swift
    import UserNotifications

    func scheduleNotification(at date: Date, with message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Journal"
        content.body = message
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.hour, .minute], from: date), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error.localizedDescription)")
            }
        }
    }
    ```
    - [x] Test notifications in the simulator.


- [x] **Voice Recording & Transcription:**  
  - [x] Integrate Apple's Speech Framework.
  - [x] Create a helper class (or extend the controller) to handle voice recording:
    ```swift
    import Speech

    class SpeechManager: NSObject, SFSpeechRecognizerDelegate {
        private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        // Additional properties and methods to start/stop recording and process transcription.
    }
    ```
  - [x] Ensure the UI displays the transcribed text in real time.

- [x] **Local Storage:**  
  - [x] Use an in-memory data model (e.g., a simple array or dictionary) to store journal entries temporarily.
  - [x] Add error handling for speech recognition failures.

- [x] **Testing & Debugging:**  
  - [x] Simulate various scenarios: successful transcription, recognition failure, and ignored notifications.
  - [x] Use logging to verify that reminders trigger as expected.

## Edge Cases & Error Handling
- **User ignores notifications** → App keeps reminding every 30 minutes until 10 PM.
- **Speech recognition fails** → Show a retry button.
- **User exits mid-session** → Journal entry is lost (to be improved in later phases).

## Dependencies & Configuration
- **Technologies**: Swift (iOS app), Apple Speech Framework, Local Notifications.
- **Permissions Needed**:
  - `NSMicrophoneUsageDescription` (for voice input)
  - `NSSpeechRecognitionUsageDescription` (for speech-to-text)
  - `NSUserNotificationUsageDescription` (for reminders)

---

This phase establishes the foundation for our journaling app. In **Phase 2**, we'll add speech-to-text functionality to make journaling even more frictionless.

**[Home](../README.md) | [Next: Phase 2](./phase_2.md)**