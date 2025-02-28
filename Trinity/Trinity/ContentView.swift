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

struct ContentView: View {
    @State private var currentPrompt = "What do you desire?"
    @State private var transcribedText = ""
    @State private var isRecording = false
    @State private var promptIndex = 0
    @State private var notificationsEnabled = false
    @State private var speechRecognitionEnabled = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var recordingStatus = "Ready to record"
    
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
            
            // Recording status
            Text(recordingStatus)
                .font(.system(size: 14))
                .foregroundColor(isRecording ? .red : .gray)
                .padding(.top, -10)
            
            Spacer()
            
            // Transcribed text area
            ScrollView {
                Text(transcribedText.isEmpty ? "Your journal entry will appear here..." : transcribedText)
                    .font(.system(size: 16))
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
            
            // Recording button
            Button(action: toggleRecording) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(isRecording ? .red : Color(hex: "#007AFF"))
            }
            .padding(.bottom, 20)
            .disabled(!speechRecognitionEnabled)
            
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
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    // Reset recording state when error is dismissed
                    isRecording = false
                    recordingStatus = "Ready to record"
                }
            )
        }
    }
    
    private func toggleRecording() {
        // Prevent multiple rapid toggles
        if recordingStatus == "Processing..." || recordingStatus == "Preparing..." {
            logger.info("Recording state transition in progress, ignoring toggle")
            return
        }
        
        if isRecording {
            // Stop recording
            logger.info("Stopping recording")
            recordingStatus = "Processing..."
            stopRecording()
            
            // Reset status after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.recordingStatus = "Ready to record"
            }
        } else {
            // Start recording and transcription
            logger.info("Starting recording for prompt: \(self.currentPrompt)")
            recordingStatus = "Preparing..."
            isRecording = true
            
            // Add a longer delay before starting recording to ensure any previous session is fully cleaned up
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.recordingStatus = "Listening..."
                self.startRecording()
            }
        }
    }
    
    private func startRecording() {
        do {
            try SpeechManager.shared.startRecording()
        } catch {
            isRecording = false
            recordingStatus = "Ready to record"
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            showingError = true
            logger.error("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        SpeechManager.shared.stopRecording()
        
        // Add a longer delay to ensure the audio session is properly cleaned up
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.isRecording = false
            logger.info("Audio session cleanup completed")
        }
    }
    
    private func setupSpeechRecognition() {
        // Set up handlers for transcription updates and errors
        logger.info("Setting up speech recognition handlers")
        
        SpeechManager.shared.transcriptionHandler = { text in
            DispatchQueue.main.async {
                // Only update transcription if we're recording
                if self.isRecording {
                    self.transcribedText = text
                    self.logger.info("Updated transcription: \"\(text)\"")
                } else {
                    self.logger.info("Received transcription while not recording, ignoring: \"\(text)\"")
                }
            }
        }
        
        SpeechManager.shared.errorHandler = { error in
            DispatchQueue.main.async {
                // Always stop recording on error
                if self.isRecording {
                    self.isRecording = false
                    self.recordingStatus = "Ready to record"
                }
                
                // Handle specific error cases
                let nsError = error as NSError
                if nsError.domain == "SpeechManager" && nsError.code == 3 {
                    // Check the error message to determine the specific case
                    if nsError.localizedDescription.contains("No additional speech detected") {
                        // User started speaking but then stopped
                        self.errorMessage = "No additional speech detected. Your entry has been saved."
                        self.showingError = true
                        self.logger.error("Speech recognition error: No additional speech detected")
                        
                        // If we have some transcribed text, save it automatically
                        if !self.transcribedText.isEmpty {
                            self.saveEntry()
                        }
                    } else {
                        // No speech detected at all
                        self.errorMessage = "No speech detected. Please try again and speak clearly."
                        self.showingError = true
                        self.logger.error("Speech recognition error: No speech detected")
                    }
                } else if nsError.domain == "kAFAssistantErrorDomain" {
                    // Speech service error - don't show alert for these as they're often transient
                    self.logger.error("Speech recognition service error: \(error.localizedDescription)")
                } else {
                    // Other errors
                    self.errorMessage = "Speech recognition error: \(error.localizedDescription)"
                    self.showingError = true
                    self.logger.error("Speech recognition error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveEntry() {
        // First stop any ongoing recording
        if isRecording {
            stopRecording()
            isRecording = false
        }
        
        // Log the current state before saving
        logger.info("Saving journal entry for prompt: \(currentPrompt) with text: \"\(transcribedText)\"")
        
        // Save the entry to local storage using JournalStore
        JournalStore.shared.saveEntry(prompt: currentPrompt, response: transcribedText)
        logger.info("Journal entry saved successfully")
        
        // Clear the transcription before moving to next prompt
        transcribedText = ""
        
        // Move to next prompt or end session
        moveToNextPrompt()
        
        // Log the state after moving to the next prompt
        logger.info("After moving to next prompt: \(currentPrompt), transcription is \(transcribedText.isEmpty ? "empty" : "not empty")")
    }
    
    private func discardEntry() {
        // First stop any ongoing recording
        if isRecording {
            stopRecording()
            isRecording = false
        }
        
        // Log the current state before discarding
        logger.info("Discarding journal entry for prompt: \(currentPrompt) with text: \"\(transcribedText)\"")
        
        // Clear the transcribed text and stay on the same prompt
        transcribedText = ""
        recordingStatus = "Ready to record"
        
        // Log the state after discarding
        logger.info("After discarding entry, transcription is \(transcribedText.isEmpty ? "empty" : "not empty")")
        
        // Force UI update to ensure transcription is cleared
        DispatchQueue.main.async {
            self.transcribedText = ""
        }
    }
    
    private func moveToNextPrompt() {
        // Clear the current transcription
        transcribedText = ""
        isRecording = false
        recordingStatus = "Ready to record"
        
        // Move to the next prompt or end session
        promptIndex = (promptIndex + 1) % prompts.count
        currentPrompt = prompts[promptIndex]
        logger.info("Moved to next prompt: \(currentPrompt), cleared previous transcription")
        
        // Ensure transcription is cleared after state update
        DispatchQueue.main.async {
            self.transcribedText = ""
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
