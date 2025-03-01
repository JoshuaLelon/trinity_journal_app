# Trinity Journal App

A simple journaling app that uses voice recording and transcription to make daily journaling frictionless.

## Project Overview

Trinity is a SwiftUI-based iOS application that helps users journal daily with minimal friction. The app sends notifications to remind users to journal and provides a simple interface for recording entries through voice.

## Technology Stack

- **Framework**: SwiftUI
- **Language**: Swift
- **APIs**: 
  - Speech Framework (for voice transcription)
  - UserNotifications (for reminders)

## Design Principles

- **Pure SwiftUI**: The app is built entirely with SwiftUI, avoiding UIKit components for a consistent development experience.
- **Clean Architecture**: Following the MVC pattern with clear separation of concerns.
- **Minimal UI**: Simple, intuitive interface focused on reducing friction in the journaling process.

## Features

- **Scheduled Notifications**: Reminders to journal at 8 AM and every 30 minutes if the user hasn't journaled.
- **Voice Recording**: One-tap recording with automatic transcription.
- **Prompt Cycling**: The app cycles through three prompts (Desire, Gratitude, Brag) to guide the journaling process.
- **Local Storage**: Journal entries are stored locally on the device.

## Project Structure

- **ContentView.swift**: Main UI for the journaling experience
- **NotificationManager.swift**: Singleton for managing notification scheduling
- **SpeechManager.swift**: Handles speech recognition and transcription
- **Info.plist**: Contains required permissions for microphone, speech recognition, and notifications

## Implementation Status

- [x] Project Setup
- [x] Configure Info.plist with required permissions
- [x] Basic UI Development
- [x] Notification Scheduling
- [x] Voice Recording & Transcription
- [ ] Local Storage Implementation
- [ ] Testing & Debugging

## Known Issues

- There are some integration issues between the ContentView and the manager classes that need to be resolved.
- AVAudioSession is showing as unavailable in macOS (this is expected as it's an iOS-only API).

## Color Palette

- Background: #FFFFFF (white)
- Primary Accent: #007AFF (iOS blue)
- Text: #333333 (dark gray)
- Secondary Background: #F5F5F5 (light gray)

## API Integration

The Trinity Journal App integrates with a FastAPI server running on EC2 for journal processing and storage.

### FastAPI Server Integration

The app connects to a FastAPI server at `ec2-3-145-81-84.us-east-2.compute.amazonaws.com:8000` which provides:

1. **Journal Processing** - Analyzes journal entries, classifies them by prompt type, and formats them
2. **Completed Prompts** - Retrieves a list of prompts completed for the current day
3. **Notion Integration** - The server handles all interactions with Notion, so the app doesn't need to connect directly

#### API Endpoints

- `POST /process` - Process a journal entry
  - Request: `JournalRequest` with transcription, current prompt, and completed prompts
  - Response: `JournalResponse` with detected prompt, formatted response, and refinement suggestions

- `GET /completed-prompts` - Get a list of prompts completed today
  - Response: Array of strings representing completed prompt types

- `GET /api/v1/health` - Check if the server is running
  - Response: Health status of the server

#### Implementation

The API integration is implemented in `JournalAPI.swift` which provides:

- `JournalAPIClient` - Singleton class for making API requests
- `JournalResponse` - Model for API responses

Example usage:

```swift
// Process a journal entry
JournalAPIClient.shared.processJournal(
    transcription: "I'm grateful for my family",
    currentPrompt: "gratitude",
    completedPrompts: []
) { response, error in
    if let response = response {
        // Handle successful response
        print("Formatted response: \(response.formattedResponse)")
        
        // Check if the entry was saved to Notion
        if response.savedToNotion {
            print("Entry saved to Notion")
        } else {
            print("Entry was not saved to Notion")
        }
    } else if let error = error {
        // Handle error
        print("Error: \(error.localizedDescription)")
    }
}

// Get completed prompts
JournalAPIClient.shared.getCompletedPrompts { prompts, error in
    if let prompts = prompts {
        // Handle completed prompts
        print("Completed prompts: \(prompts)")
    } else if let error = error {
        // Handle error
        print("Error: \(error.localizedDescription)")
    }
}
```

### API Connection Testing

The app includes an API connection test view (`APIConnectionTest.swift`) that allows you to:

1. **Test FastAPI Server Connection** - Checks if the FastAPI server is accessible

To use the API connection test:

1. Navigate to the API Connection Test view in the app
2. Click "Test Server Connection" to check if the FastAPI server is accessible

## Troubleshooting

### FastAPI Server Connection Issues

If you're having trouble connecting to the FastAPI server:

1. **Check if the server is running** - Make sure your EC2 instance is running and the FastAPI server is started with `python run.py`
2. **Verify the port** - The server runs on port 8000, not the default HTTP port 80
3. **Check security groups** - Ensure your EC2 security group allows inbound traffic on port 8000
4. **Check network connectivity** - Make sure your device has internet access and can reach the EC2 instance

### Notion API Issues

If the server returns errors related to Notion:

1. **Check the server logs** - The server may be having trouble connecting to Notion
2. **Verify the Notion API key on the server** - Make sure the server has a valid Notion API key
3. **Check the database ID on the server** - Verify that the database ID in the server configuration matches your Notion database

## Usage

See `JournalView.swift` for a complete example of how to use the API client in a SwiftUI view. 