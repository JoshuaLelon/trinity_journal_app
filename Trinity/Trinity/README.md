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

## Building and Installing on Physical Devices

To build and install the app on a physical iOS device using the command line, follow these steps:

### 1. Find Your Device ID

First, you need to get your device's identifier:

```bash
xcrun xctrace list devices
```

This will show a list of available devices. Look for your physical device in the format:
```
iPhone Name (iOS Version) (device-id)
```

### 2. Clean the Project

Clean the project to ensure a fresh build:

```bash
cd /path/to/Trinity
xcodebuild clean -project Trinity.xcodeproj -scheme Trinity
```

### 3. Build and Install

Use the following command to build and install the app on your device:

```bash
xcodebuild -project Trinity.xcodeproj -scheme Trinity -destination "platform=iOS,arch=arm64,id=YOUR_DEVICE_ID" clean build install
```

Replace `YOUR_DEVICE_ID` with your actual device ID from step 1.

For example:

```bash
xcodebuild -project Trinity.xcodeproj -scheme Trinity -destination "platform=iOS,arch=arm64,id=00008030-000D49481AB9802E" clean build install
```

### Troubleshooting Installation Issues

If you encounter the "Failed to install the app on the device" error (CoreDeviceError 3002):

1. Make sure you're using the correct device ID
2. Ensure your provisioning profile is valid and includes your device
3. Check that your Apple Developer account has the device registered
4. Verify that your device is trusted on your Mac
5. Try restarting both your Mac and iOS device
6. Ensure you have at least 500MB of free space on your device

### Common Error Codes

- **CoreDeviceError 3002**: Failed to install the app on the device
- **CoreDeviceError 3004**: Device is locked
- **CoreDeviceError 3007**: Device is not connected

## HTTP Connection Issues (App Transport Security)

If you're seeing this error:
> "The resource could not be loaded because the App Transport Security policy requires the use of a secure connection."

This is happening because iOS requires HTTPS connections by default. We've implemented three solutions:

### Solution 1: Custom URLSession in Network Classes
We've updated both `ServerAPI.swift` and `JournalStore.swift` to use custom URLSession configurations that are prepared to handle HTTP connections. This should work for most development cases.

### Solution 2: Info.plist Configuration (Implemented)
We've created a custom Info.plist file with the proper App Transport Security settings:

1. Created a physical Info.plist file in the Trinity directory
2. Added the following ATS configuration:
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSExceptionDomains</key>
       <dict>
           <key>ec2-3-145-81-84.us-east-2.compute.amazonaws.com</key>
           <dict>
               <key>NSExceptionAllowsInsecureHTTPLoads</key>
               <true/>
               <key>NSIncludesSubdomains</key>
               <true/>
               <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
               <true/>
           </dict>
       </dict>
   </dict>
   ```
3. Updated the project settings to use this Info.plist file instead of the generated one
4. **Important**: Removed all `INFOPLIST_KEY_*` entries from project.pbxproj to avoid conflicts between the physical Info.plist and generated plist entries

### Fixing Info.plist Build Conflicts

If you encounter this error:
> Multiple commands produce '/Users/jm/Library/Developer/Xcode/DerivedData/Trinity-*/Build/Products/Debug-iphoneos/Trinity.app/Info.plist'

This happens when Xcode tries to both:
1. Copy the physical Info.plist file AND
2. Generate an Info.plist from build settings

The solution is to:
1. Ensure `GENERATE_INFOPLIST_FILE = NO` in project settings
2. Remove all `INFOPLIST_KEY_*` entries from project.pbxproj
3. Make sure all needed Info.plist keys are in the physical Info.plist file
4. Run a clean build (`Product > Clean Build Folder` in Xcode)

### Long-term Solution (Recommended)
The best solution is to configure your EC2 server with HTTPS:
1. Get a domain name for your server
2. Set up a free SSL certificate using Let's Encrypt
3. Configure your FastAPI server with HTTPS support
4. Update all URLs in the app to use HTTPS instead of HTTP 