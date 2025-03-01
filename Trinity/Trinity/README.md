# Trinity Journal App

## Overview
Trinity is a voice-first journaling app that uses speech recognition to capture daily reflections based on three core prompts: desires, gratitudes, and brags. The app transcribes your spoken responses and integrates with Notion to store these reflections in a structured format.

## Core Components

### Managers
- **SpeechManager**: Handles speech recognition and transcription
- **NotificationManager**: Manages daily reminders
- **JournalStore**: Stores journal entries locally and syncs with Notion

### Models
- **JournalEntry**: Represents a single response to a prompt
- **JournalEntryData**: Codable version for storage

### Integration
- **NotionAPIClient**: Handles all Notion API interactions

## Notion Integration
The app integrates with Notion to store journal entries in a structured database:

1. **Finding the Daily Page**: The app looks for a page titled "Daily: @Today" in your Notion database
2. **Structured Data**: Each prompt type is stored in its respective field (desires, gratitudes, brags)
3. **Error Handling**: Provides feedback for success/failure of Notion operations
4. **Retry Mechanism**: Allows retrying failed uploads

### API Contract
The app uses the following Notion API endpoints:
- `POST /v1/databases/{database_id}/query` - To find the Daily page
- `PATCH /v1/pages/{page_id}` - To update the Daily page with journal entries

## Getting Started
To use the Notion integration:

1. Obtain a Notion API key from the [Notion Integrations page](https://www.notion.so/my-integrations)
2. Ensure your Notion database has a page titled "Daily: @Today" with the following properties:
   - "desires" (rich text property)
   - "gratitudes" (rich text property)
   - "brags" (rich text property)
3. Share the database with your integration
4. Update the API key using the secure storage system

## Security Considerations
The app uses the following security measures:
- Keychain Services API for securely storing the Notion API key
- No hardcoded API keys in the source code
- Clear separation of credential storage from business logic 

## Build Error Resolution

### Recent Changes (Updated)
1. Removed direct Notion integration and replaced it with calls to a FastAPI server.
2. Deleted conflicting files:
   - `NotionAPIClient.swift` - Replaced by using the FastAPI server
   - `JournalAPI.swift` - Replaced by using `ServerAPI.swift` 
   - `JournalAPITest.swift` - Replaced by `ServerAPITest.swift`
   - `JournalAPIExample.swift` - Duplicate implementation of ServerAPI functionality
   - `JournalView.swift` - Duplicate implementation of ServerAPITest functionality
   - `TrinityImports.swift` - Caused redeclaration issues

3. Updated method names:
   - Changed `uploadEntriesToNotion` to `uploadEntriesToServer` in `JournalStore.swift`
   - Changed `notionUploadStatusHandler` to `uploadStatusHandler` in `JournalStore.swift`

### Fixing Persistent Build Issues

If you still encounter build errors:

1. **Clean the build folder**: 
   - In Xcode, hold the Option key and click Product > Clean Build Folder
   - Or run `rm -rf ~/Library/Developer/Xcode/DerivedData/*` in Terminal

2. **Reset Xcode if needed**:
   - Quit Xcode completely
   - Run `defaults delete com.apple.dt.Xcode` in Terminal to reset Xcode's cache
   - Reopen Xcode and the project

3. **JournalComponents.swift issues**:
   - This file is referenced in the build system but doesn't exist in the project. 
   - You can safely remove it from the project if it appears in Xcode's file navigator.

4. **For Objective-C module errors**:
   - Update the project settings to ensure modules are properly enabled
   - Go to Build Settings > Packaging > Defines Module and set to Yes
   - Check that your module name matches your product name

### Project Structure

The project now has a cleaner structure:

1. `ServerAPI.swift` - Contains the core API models and client
2. `ServerAPITest.swift` - Provides a test UI for the server API
3. `JournalStore.swift` - Handles local storage and server sync
4. `ContentView.swift` - Main app interface
5. `SpeechManager.swift` - Handles speech recognition
6. `NotificationManager.swift` - Manages notifications

### Testing 

After fixing build issues, you can test the server integration using:

1. `ServerAPITest.swift` - A simple test UI for checking connectivity to the FastAPI server
2. `JournalStore.swift` - Handles saving entries locally and sending them to the server

All communication with Notion now happens through the FastAPI server, making the iOS app simpler and more focused. 