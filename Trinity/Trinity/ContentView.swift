//
//  ContentView.swift
//  Trinity
//
//  Created by Joshua Mitchell on 2/28/25.
//

import SwiftUI
import Speech
import UserNotifications
import os.log
import Foundation

// The ContentView needs to be in the same module as the manager classes
// so we don't need to import them explicitly

// Define a state enum for recording states
enum RecordingState {
    case idle
    case recording
    case transcribing
    case completed
}

struct ContentView: View {
    @State private var currentPrompt = "What do you desire?"
    @State private var transcribedText = ""
    @State private var isRecording = false {
        didSet {
            // Update recording status whenever isRecording changes
            if isRecording {
                if recordingStatus != "Listening..." && recordingStatus != "Preparing..." {
                    recordingStatus = "Preparing..."
                }
            } else {
                if recordingStatus == "Listening..." {
                    recordingStatus = "Processing..."
                }
            }
        }
    }
    @State private var promptIndex = 0
    @State private var notificationsEnabled = false
    @State private var speechRecognitionEnabled = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var recordingStatus = "Ready to record"
    @State private var currentState: RecordingState = .idle
    @State private var silenceTimer: Timer?
    @State private var showRetryButton = false
    
    // Create a logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.trinity.journal", category: "ContentView")
    
    // Array of prompts to cycle through
    private let prompts = [
        "What do you desire?",
        "What are you grateful for?",
        "What can you brag about today?"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Prompt display
            Text(currentPrompt)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: "#333333"))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 40)
            
            // Recording status with slightly more prominence
            Text(recordingStatus)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isRecording ? .red : .gray)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isRecording ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            Spacer()
            
            // Transcribed text area
            ScrollView {
                Text(transcribedText.isEmpty ? "Your journal entry will appear here..." : transcribedText)
                    .font(.system(size: 18))
                    .foregroundColor(transcribedText.isEmpty ? .gray : Color(hex: "#333333"))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#F5F5F5"))
            .cornerRadius(12)
            .shadow(radius: 2)
            .padding(.horizontal)
            
            Spacer()
            
            // Recording indicator (replaces the button)
            if isRecording {
                HStack(spacing: 15) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .opacity(0.8)
                    
                    Text("Recording in progress...")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
                .padding(.bottom, 10)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#007AFF")))
                    .scaleEffect(1.5)
                    .padding(.bottom, 20)
            }
            
            if showRetryButton && !transcribedText.isEmpty {
                Button(action: retryTranscription) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 20))
                        Text("Retry")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#007AFF"))
                    .cornerRadius(10)
                }
                .padding(.bottom, 20)
                .disabled(!speechRecognitionEnabled)
            }
            
            // Save or discard buttons
            if !transcribedText.isEmpty {
                HStack(spacing: 30) {
                    Button(action: discardEntry) {
                        Text("Discard")
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#F5F5F5"))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                    
                    Button(action: saveEntry) {
                        Text("Save")
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#007AFF"))
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .padding()
        .onAppear {
            // Request permissions when the app launches
            requestPermissions()
            
            // Set up speech recognition handlers
            setupSpeechRecognition()
            
            // Auto-start recording after a short delay to ensure permissions are processed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if self.speechRecognitionEnabled && !self.isRecording {
                    self.logger.info("Auto-starting recording for initial prompt")
                    self.startRecordingForPrompt()
                }
            }
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    // Reset recording state when error is dismissed
                    isRecording = false
                    recordingStatus = "Ready to record"
                    currentState = .idle
                    
                    // If speech recognition error, show retry button
                    // Otherwise, auto-restart recording after a delay
                    if errorMessage?.contains("No speech detected") == true {
                        showRetryButton = true
                    } else {
                        // Auto-restart recording after error dismissal 
                        // with a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            if self.speechRecognitionEnabled && !self.isRecording && self.currentState == .idle {
                                self.logger.info("Auto-restarting recording after error")
                                self.startRecordingForPrompt()
                            }
                        }
                    }
                }
            )
        }
    }
    
    // New method to centralize recording start logic
    private func startRecordingForPrompt() {
        // Prevent starting if already recording
        if isRecording {
            logger.info("Already recording, not starting again")
            return
        }
        
        // Start recording and transcription
        logger.info("Starting recording for prompt: \(self.currentPrompt)")
        isRecording = true
        currentState = .recording
        
        // Add a delay before starting recording to ensure any previous session is fully cleaned up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Double check we're still in recording state
            guard self.isRecording else {
                self.logger.info("Recording state changed during preparation, cancelling start")
                return
            }
            
            self.startRecording()
            
            // Remove the silence detection timer to allow indefinite recording
            self.logger.info("Recording will continue indefinitely until manually stopped")
        }
    }
    
    private func startRecording() {
        do {
            try SpeechManager.shared.startRecording()
            // Update recording status when recording starts
            DispatchQueue.main.async {
                self.recordingStatus = "Listening..."
            }
        } catch {
            isRecording = false
            recordingStatus = "Ready to record"
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            showingError = true
            logger.error("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        // Log that we're stopping recording
        logger.info("Stopping recording and cleaning up audio session")
        
        // Immediately update UI state to show we're not recording anymore
        isRecording = false
        recordingStatus = "Processing..."
        
        // Stop the recording
        SpeechManager.shared.stopRecording()
        
        // Cancel any running timers (keeping this for safety in case timers are added elsewhere)
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        // Set status back to ready after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.recordingStatus = "Ready to record"
            
            // Only set to transcribing if we're not already in a different state (like idle)
            // This prevents overriding the idle state set by moveToNextPrompt
            if self.currentState == .recording {
                self.currentState = .transcribing
            }
            self.logger.info("Audio session cleanup completed")
        }
    }
    
    private func setupSpeechRecognition() {
        // Set up handlers for transcription updates and errors
        logger.info("Setting up speech recognition handlers")
        
        SpeechManager.shared.transcriptionHandler = { (text: String) in
            DispatchQueue.main.async {
                // Update transcription if we have text, regardless of recording state
                // This ensures we don't miss transcription during state transitions
                if !text.isEmpty {
                    self.transcribedText = text
                    if self.isRecording {
                        self.logger.info("Updated transcription: \"\(text)\"")
                    } else {
                        self.logger.info("Updated transcription while not recording: \"\(text)\"")
                    }
                }
            }
        }
        
        SpeechManager.shared.errorHandler = { (error: Error) in
            DispatchQueue.main.async {
                let nsError = error as NSError
                
                // Ignore "No speech detected" errors to allow indefinite waiting
                if nsError.domain == "SpeechManager" && nsError.code == 3 {
                    if nsError.localizedDescription.contains("No additional speech detected") || 
                       nsError.localizedDescription.contains("No speech detected") {
                        // Log the error but don't show it to the user and don't stop recording
                        self.logger.info("Ignoring 'No speech detected' error to allow indefinite waiting")
                        return
                    }
                } else if nsError.domain == "kAFAssistantErrorDomain" && 
                          (nsError.localizedDescription.contains("No speech detected") || 
                           nsError.localizedDescription.contains("No speech")) {
                    // Also ignore Apple's speech service errors about no speech
                    self.logger.info("Ignoring Apple speech service 'No speech' error")
                    return
                }
                
                // For all other errors, proceed with normal error handling
                
                // Always stop recording on error
                if self.isRecording {
                    self.isRecording = false
                    self.recordingStatus = "Ready to record"
                    self.currentState = .idle
                }
                
                // Handle other error cases
                if nsError.domain == "kAFAssistantErrorDomain" {
                    // Speech service error - handle more gracefully
                    self.logger.error("Speech recognition service error: \(error.localizedDescription)")
                    
                    // If we're in the middle of recording, show a more user-friendly error
                    if self.currentState == .recording || self.currentState == .transcribing {
                        self.errorMessage = "Speech recognition service temporarily unavailable. Please try again in a moment."
                        self.showingError = true
                        self.showRetryButton = true
                    }
                    
                    // Reset state to allow retry
                    self.currentState = .idle
                } else {
                    // Other errors
                    self.errorMessage = "Speech recognition error: \(error.localizedDescription)"
                    self.showingError = true
                    self.logger.error("Speech recognition error: \(error.localizedDescription)")
                    self.showRetryButton = true
                }
            }
        }
    }
    
    private func saveEntry() {
        logger.info("Saving entry for prompt: \(currentPrompt)")
        
        // First, ensure all recording resources are properly cleaned up
        if isRecording {
            // Stop recording if it's still in progress
            logger.info("Recording still in progress during save, stopping it first")
            stopRecording()
            
            // Wait for cleanup to complete before proceeding
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.completeSaveAndMoveToNext()
            }
        } else {
            // If not recording, proceed immediately
            completeSaveAndMoveToNext()
        }
    }
    
    private func completeSaveAndMoveToNext() {
        // Make sure silence timer is canceled
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        // Save to journal store using the existing method
        let currentResponse = transcribedText // Capture current text before clearing
        JournalStore.shared.saveEntry(prompt: currentPrompt, response: currentResponse)
        
        // Reset UI state
        transcribedText = ""
        isRecording = false
        recordingStatus = "Ready to record"
        currentState = .idle
        showRetryButton = false
        
        // Move to next prompt - this schedules the auto-start
        moveToNextPrompt()
    }
    
    private func discardEntry() {
        logger.info("Discarding entry for prompt: \(currentPrompt)")
        
        // Reset UI state
        transcribedText = ""
        isRecording = false
        recordingStatus = "Ready to record"
        currentState = .idle
        showRetryButton = false
        
        // Cancel any running timers
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        // Auto-start recording again for the same prompt after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if self.speechRecognitionEnabled && !self.isRecording && self.currentState == .idle {
                self.logger.info("Auto-restarting recording after discard")
                self.startRecordingForPrompt()
            }
        }
    }
    
    private func moveToNextPrompt() {
        // Clear the current transcription
        transcribedText = ""
        isRecording = false
        recordingStatus = "Ready to record"
        
        // Set state to idle and log the state change
        self.currentState = .idle
        logger.info("State reset to idle for next prompt")
        
        // Move to the next prompt or end session
        promptIndex = (promptIndex + 1) % prompts.count
        currentPrompt = prompts[promptIndex]
        logger.info("Moved to next prompt: \(currentPrompt), cleared previous transcription")
        
        // Ensure transcription is cleared after state update
        DispatchQueue.main.async {
            self.transcribedText = ""
        }
        
        // Set a flag to prevent immediate recording in another part of the code
        let tempPromptIndex = promptIndex
        
        // Use a longer delay (8 seconds instead of 5) to ensure the previous audio session 
        // is fully cleaned up, and any silence timer that might be running has finished
        logger.info("Scheduling auto-start for next prompt in 8 seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            // Check if we're still on the same prompt (no user interaction in between)
            if self.promptIndex != tempPromptIndex {
                self.logger.info("Prompt changed since scheduling auto-start, cancelling auto-start")
                return
            }
            
            // Force state to idle again just before checking conditions
            // This ensures any delayed operations that changed the state won't interfere
            self.currentState = .idle
            
            self.logger.info("Auto-start timer fired, checking conditions")
            self.logger.info("Speech recognition enabled: \(self.speechRecognitionEnabled), isRecording: \(self.isRecording), currentState: \(String(describing: self.currentState))")
            
            // Additional check to ensure we're not in the middle of a cleanup
            guard !SpeechManager.shared.isInCleanupState else {
                self.logger.info("Not auto-starting: SpeechManager is still cleaning up")
                
                // Try again after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.speechRecognitionEnabled && !self.isRecording && self.currentState == .idle {
                        self.logger.info("Retrying auto-start after delay")
                        self.startRecordingForPrompt()
                    }
                }
                return
            }
            
            if self.speechRecognitionEnabled && !self.isRecording && self.currentState == .idle {
                self.logger.info("Auto-starting recording for next prompt after delay")
                self.startRecordingForPrompt()
            } else {
                self.logger.info("Not auto-starting: conditions not met")
            }
        }
    }
    
    private func requestPermissions() {
        // Request speech recognition permissions
        SpeechManager.shared.requestPermissions { granted in
            DispatchQueue.main.async {
                self.speechRecognitionEnabled = granted
                
                if !granted {
                    self.errorMessage = "Speech recognition permission denied. Please enable it in Settings."
                    self.showingError = true
                }
            }
        }
        
        // Request notification permissions
        requestNotificationPermissions()
    }
    
    private func requestNotificationPermissions() {
        let notificationManager = NotificationManager.shared
        notificationManager.requestPermissions { granted in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                
                if granted {
                    // Schedule notifications if permissions are granted
                    notificationManager.scheduleMorningNotification()
                    print("Notifications scheduled successfully")
                } else {
                    print("Notification permissions denied")
                }
            }
        }
    }
    
    // Add a retry transcription function
    private func retryTranscription() {
        // Clear the current transcription
        transcribedText = ""
        showRetryButton = false
        
        // Start recording again
        logger.info("Retrying transcription for prompt: \(self.currentPrompt)")
        startRecordingForPrompt()
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
