# Phase 3: Notion API Integration

**[Home](../README.md) | [Previous: Phase 2](./phase_2.md) | [Next: Phase 4](./phase_4.md)**

---

## Problem Statement
Users want their journal entries stored in Notion for better organization and accessibility. The app should seamlessly integrate with Notion to store entries in a structured format.

## Solution Overview
In this phase, we implement:
- Connection to the Notion API to store journal entries. (for now the app will connect directly to the notion page via the Notion API, but in the future we will connect to the backend and that backend will connect to Notion)
- A structured format where each prompt (Desire, Gratitude, Brag) is stored in its respective field in a Notion daily note.
- Error handling for failed API requests.
- A confirmation message after successful storage.

---

## Feature List
### **Existing (From Previous Phase)**
- **Notifications**: Sent at 8 AM, then every 30 minutes if the user hasn't journaled.
- **UI**: Displays current prompt and transcribed response.
- **Speech-to-Text**: Automatic transcription when the app is opened.
- **Local Storage**: Responses temporarily stored in memory.
- **Journaling Flow**:
  - User opens the app
  - The app queries Notion to see what prompts already have a response recorded and shows the next prompt (if unfinished)
  - Recording begins automatically.
  - Speech is transcribed and displayed.
  - User can save the response or re-transcribe.
  - App moves to the next prompt.
  - If all prompts are finished, the app shows a completion message.

### **New (Implemented in This Phase)**
- **Notion API Integration**:
  - Append each prompt response under the appropriate field in the daily note.
- **Success Confirmation**:
  - Display a message confirming the entry was saved to Notion.
- **Error Handling**:
  - Handle failures due to no internet or API errors.
  - Show an error message if saving to Notion fails.

## UI & Styling Guidelines
- **Notification of Success/Error:**  
  - Use modal popups with clear messages.
  - Success modals: green accents; error modals: red accents.
- **Consistent Style:**  
  - Maintain Phase 1 and 2 styling.  
  - Use consistent button styling for "Confirm" or "Retry" actions.
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
- **Facade Pattern:**  
  Implement a `NotionAPIClient` as a facade to encapsulate all Notion-related API calls.
- **Singleton Pattern:**  
  Use a singleton for configuration and authentication with Notion.
- **MVC:**  
  Integrate the Notion API in the model layer, keeping the controller slim.

## Implementation Checklist
- [ ] **Backend Setup:**  
  - [ ] implement direct Notion API calls from the iOS app (using HTTPS requests).
- [ ] **Notion API Client:**  
  - [ ] Create a `NotionAPIClient` class:
    ```swift
    class NotionAPIClient {
        static let shared = NotionAPIClient()
        private init() {}
        
        func sendEntry(date: String, promptData: [String: [String]], completion: @escaping (Bool, String?) -> Void) {
            // Construct URLRequest and handle API call to Notion
            // (Include error handling and JSON parsing)
        }
    }
    ```
  - [ ] Securely store and access the Notion API key.
- [ ] **Mapping Data:**  
  - [ ] Define the data model to structure journal entries:
    ```swift
    struct JournalEntry: Codable {
        let date: String
        let gratitude: [String]
        let desire: [String]
        let brag: [String]
    }
    ```
- [ ] **UI Integration:**  
  - [ ] After the user saves an entry locally, trigger the Notion API call.
  - [ ] Show a modal popup confirming success or prompting a retry in case of error.
- [ ] **Testing & Debugging:**  
  - [ ] Test API responses for both success and failure scenarios.
  - [ ] Log API errors for troubleshooting.


## Flow Diagrams

### **Sequence Diagram**
See [Phase 3 Sequence Diagram](./diagrams/phase_3_sequence_diagram.md)

### **Flow Diagram**
See [Phase 3 Flow Diagram](./diagrams/phase_3_flow_diagram.md)

---

## API Contracts & Example Requests/Responses

Note: Confirm via notion api docs that we are able to update one property at a time and that this is how we would do it. Also get an example for how to read the daily note for today.

### **Request (Sending to Notion API)**
```json
POST /send_to_notion
{
  "date": "2025-03-01",
  "gratitude": ["I am grateful for my health."],
}
```

### **Response (Success)**
```json
{
  "status": "success",
  "message": "Entry saved to Notion"
}
```

### **Response (Failure)**
```json
{
  "status": "error",
  "message": "Failed to connect to Notion API. Please check your internet connection."
}
```

---

## Edge Cases & Error Handling
- **No internet connection** → Show an error and allow retry.
- **Notion API fails** → Display an error and allow retry.

---

## Dependencies & Configuration
- **Technologies**: Swift (iOS app), Notion API.
- **Permissions Needed**:
  - `NSMicrophoneUsageDescription` (for voice input)
  - `NSSpeechRecognitionUsageDescription` (for speech-to-text)
  - `NSUserNotificationUsageDescription` (for reminders)
  - Notion API authentication key.

---

This phase enables users to store their journal entries in Notion for better organization. In **Phase 4**, we'll add AI-powered prompt switching and formatting capabilities.

**[Home](../README.md) | [Previous: Phase 2](./phase_2.md) | [Next: Phase 4](./phase_4.md)**