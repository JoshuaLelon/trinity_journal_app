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