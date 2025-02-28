# Phase 2: Speech-to-Text Integration

**[Home](../README.md) | [Previous: Phase 1](./phase_1.md) | [Next: Phase 3](./phase_3.md)**

---

## Problem Statement
Users want to journal without typing. The app should allow users to speak their journal entries, which are then transcribed automatically.

## Solution Overview
In this phase, we implement:
- Automatic voice recording as soon as the app is opened.
- UI improvements to better display prompts and transcriptions.
- A retry option if speech recognition fails.

---

## Feature List
### **Existing (From Previous Phase)**
- **Notifications**: Sent at 8 AM, then every 30 minutes if the user hasn't journaled.
- **UI**: Basic screen displaying the current prompt.
- **Speech-to-Text**: Automatic transcription when the user speaks.
- **Local Storage**: Responses saved locally in memory.
- **Journaling Flow**:
  - User opens the app and sees a prompt.
  - User starts recording manually.
  - Speech is transcribed and displayed on the screen.
  - User can save or discard the response.
  - App cycles through prompts in a fixed order (Desire → Gratitude → Brag).

### **New (Implemented in This Phase)**
- **Auto-start recording**: Voice recording begins immediately when the app is opened. If 15 seconds of silence is detected, the recording will stop automatically. Or, if the user taps a button to stop recording, the recording will stop.
- **Dynamic UI updates**:
  - Current prompt is displayed more clearly.
  - Transcriptions appear in real-time.
- **Retry speech recognition if it fails**.
- **Allow user to re-transcribe responses before saving**. Perhaps a button to re-transcribe the response and a button to save the response as is.

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
- **Layout Enhancements:**  
  - Introduce a progress indicator or subtle animation while recording.
  - Use card-style views to display prompts and transcriptions.
- **Colors & Fonts:**  
  - Maintain Phase 1 color palette.
  - Use a slightly larger font for real-time transcription display (18pt, regular).
- **Interactive Elements:**  
  - Clearly styled "Retry" and "Save" buttons with a shadow effect for depth.
  - Visual feedback (e.g., change button color) when recording starts/stops.

## Design Patterns & Architecture
- **Delegate Pattern:**  
  Use delegates to communicate between the speech recognition manager and the view controller.
- **State Pattern:**  
  Manage the state of the journaling session (e.g., Idle, Recording, Transcribing, Completed) to streamline UI transitions.
- **MVC:**  
  Continue leveraging MVC, with refinements in controller logic for auto-starting recording.

## Implementation Checklist
- [ ] **Auto-Start Recording:**  
  - [ ] Update the view controller to trigger recording in `viewDidAppear()`.
  - [ ] Integrate a state machine to handle recording states:
    ```swift
    enum RecordingState {
        case idle, recording, transcribing, completed
    }
    ```
  - [ ] Display an animated indicator while recording.
    
    Code Example: Auto-Starting Voice Recording
    ```swift
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Automatically start recording when the view appears
        SpeechManager.shared.startRecording { [weak self] result, error in
            guard let self = self else { return }
            if let transcription = result {
                self.transcriptionLabel.text = transcription
                self.currentState = .transcribing
            } else if let error = error {
                print("Transcription error: \(error.localizedDescription)")
                self.showRetryOption()
            }
        }
    }
    ```

- [ ] **UI Enhancements:**  
  - [ ] Design a dynamic prompt card with rounded corners and a subtle drop shadow.
  - [ ] Implement a real-time transcription view that updates as the user speaks.
  - [ ] Add "Retry" and "Save" buttons below the transcription:
    ```swift
    // Example button style in SwiftUI:
    Button(action: retryTranscription) {
        Text("Retry")
            .font(.system(size: 16, weight: .medium))
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(10)
    }
    ```

- [ ] **Handling Transcription Failures:**  
  - [ ] Provide a retry mechanism if transcription fails.
  - [ ] Use a delegate method to notify the view controller when transcription is complete or if an error occurs.

- [ ] **Testing & Debugging:**  
  - [ ] Test auto-start recording across different app states.
  - [ ] Verify that UI elements update correctly based on state changes.


## Flow Diagrams

### **Sequence Diagram**
See [Phase 2 Sequence Diagram](./diagrams/phase_2_sequence_diagram.md)

### **Flow Diagram**
See [Phase 2 Flow Diagram](./diagrams/phase_2_flow_diagram.md)

---

## Edge Cases & Error Handling
- **User exits immediately after opening** → Discard any partial transcription and session (to be improved in later phases).
- **Speech recognition fails** → Show retry option.
- **App crashes mid-session** → Entry is lost (to be improved in later phases).

---

## Dependencies & Configuration
- **Technologies**: Swift (iOS app), Apple Speech Framework.
- **Permissions Needed**:
  - `NSMicrophoneUsageDescription` (for voice input)
  - `NSSpeechRecognitionUsageDescription` (for speech-to-text)
  - `NSUserNotificationUsageDescription` (for reminders)

---

This phase significantly reduces the friction in journaling by allowing users to speak rather than type. In **Phase 3**, we'll integrate with Notion to store journal entries.

**[Home](../README.md) | [Previous: Phase 1](./phase_1.md) | [Next: Phase 3](./phase_3.md)**

