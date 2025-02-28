# Phase 5: Smarter Reminders & Tracking Completion

**[Previous: Phase 4](./phase_4.md) | [Next: Phase 6](./phase_6.md)**

---

## Problem Statement
The current notification system does not track whether the user has completed journaling for the day. It should intelligently adjust reminders based on whether journaling is complete, preventing unnecessary notifications while ensuring users stay on track.

## Solution Overview
In this phase, we implement:
- Smarter notifications that stop once journaling is finished.

---

## Feature List
### **Existing (From Previous Phase)**
- **AI-Based Prompt Classification**: Determines whether responses match the expected prompt and switches if needed.
- **Dynamic Prompt Switching**: Adjusts based on user input.
- **Notion API Integration**: Stores journal responses externally.
- **Speech-to-Text & UI**: Enables voice journaling with automatic transcription.
- **Tracking Journaling Completion**:
  - Track which prompts have been answered for the day.
  - Consider journaling complete only when all three prompts (Desire, Gratitude, Brag) have been answered.

### **New (Implemented in This Phase)**
- **Intelligent Notifications**:
  - Stop notifications once all prompts are completed.

---

## Flow Diagrams


### **Mermaid Sequence Diagram**
```mermaid
sequenceDiagram
    participant User
    participant App
    participant AIEngine
    participant NotionAPI
    participant AppleSpeechAPI
    participant NotificationSystem
    
    NotificationSystem->>User: Sends 8 AM notification
    User->>App: Opens app
    App->>NotionAPI: Query for completed prompts
    NotionAPI->>App: Returns completion status
    
    alt All prompts completed
        App->>NotificationSystem: Disable further reminders
        App->>User: Show completion message
    else Some prompts incomplete
        App->>User: Display next incomplete prompt
        App->>AppleSpeechAPI: Starts voice recognition
        AppleSpeechAPI->>App: Returns transcribed text
        App->>AIEngine: Classify response
        AIEngine-->>App: Determines correct prompt
        App->>User: Lets them know that the prompt has changed (if needed)
        App->>User: Asks them if there is anything else they would like to add
        App->>AppleSpeechAPI: Starts voice recognition
        AppleSpeechAPI->>App: Returns transcribed text
        App->>AIEngine: Classify response
        AIEngine-->>App: Determines that it's still the same prompt
        App->>User: Asks them if there is anything else they would like to add
        User->>App: User says no
        App->>NotionAPI: Sends formatted response to Notion
        NotionAPI->>App: Confirms save
        
        alt All prompts now completed
            App->>NotificationSystem: Disable further reminders
            App->>User: Show completion message
        else Some prompts still incomplete
            App->>User: Moves to next prompt
            App->>NotificationSystem: Schedule next reminder if user exits
            NotificationSystem->>User: Sends reminder after 30 minutes if needed
        end
    end
```

### **Mermaid Flow Diagram**
```mermaid
flowchart TD
    A[8 AM Notification] -->|User Opens App| B[Query Notion for Completion Status]
    A -->|User Ignores| C[Schedule Next Reminder]
    B -->|Check Status| D{All Prompts Completed?}
    D -->|Yes| E[Disable Further Reminders]
    D -->|No| F[Display Next Incomplete Prompt]
    
    F --> G[Start Voice Recognition]
    G --> H[Transcribe Speech]
    H --> I[AI Classification]
    I --> J{Matches Current Prompt?}
    
    J -->|Yes| K[Continue with Current Prompt]
    J -->|No| L[Notify User of Prompt Change]
    L --> K
    
    K --> M[Ask User to Add More]
    M -->|User Adds More| G
    M -->|User Says No| N[Save to Notion]
    
    N --> O{All Prompts Now Completed?}
    O -->|Yes| E
    O -->|No| P{User Continues Session?}
    
    P -->|Yes| F
    P -->|No| C
    
    C --> Q[Send Reminder in 30 Minutes]
    Q --> R{Is it Past Cutoff Time?}
    R -->|Yes| S[Stop Reminders Until Tomorrow]
    R -->|No| T[Wait for User Response]
    
    T -->|User Opens App| B
    T -->|User Ignores| C
    
    E --> U[Show Completion Message]
```

---

## API Contracts & Example Requests/Responses
### **Request (Checking Completion Status)**
```json
GET /journal_status?date=2025-03-01
```

### **Response (Incomplete Journaling)**
```json
{
  "status": "incomplete",
  "completed_prompts": ["gratitude"],
  "remaining_prompts": ["desire", "brag"]
}
```

### **Response (Completed Journaling)**
```json
{
  "status": "complete",
  "message": "User has completed all prompts for today."
}
```

### **Request (Mark Journaling as Complete Manually)**
```json
POST /complete_journaling
{
  "date": "2025-03-01"
}
```

### **Response (Success)**
```json
{
  "status": "success",
  "message": "Journaling marked as complete. No further reminders today."
}
```

---

## Edge Cases & Error Handling
- **User completes one or two prompts but exits** → The app should remind them to finish the remaining prompts.
- **User manually marks journaling as complete without answering prompts** → Allow it, but display a confirmation message.
- **App crashes mid-session** → Ensure the app resumes from the last prompt instead of restarting.
- **Notion API fails** → Store locally and retry later.

---

## Dependencies & Configuration
- **Technologies**: Swift (iOS app), FastAPI (backend), Notion API.
- **Permissions Needed**:
  - `NSUserNotificationUsageDescription` (for reminders)
  - Notion API authentication key.

---

This phase ensures the app intelligently stops and resumes reminders based on completion.

**[Previous: Phase 4](./phase_4.md)

