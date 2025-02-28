//
//  ContentView.swift
//  Trinity
//
//  Created by Joshua Mitchell on 2/28/25.
//

import SwiftUI
import Speech
import UserNotifications

// Import the manager classes
import Foundation

struct ContentView: View {
    @State private var currentPrompt = "What do you desire?"
    @State private var transcribedText = ""
    @State private var isRecording = false
    @State private var promptIndex = 0
    @State private var notificationsEnabled = false
    @State private var speechRecognitionEnabled = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
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
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        
        if isRecording {
            // Start recording and transcription
            startRecording()
        } else {
            // Stop recording
            stopRecording()
        }
    }
    
    private func startRecording() {
        do {
            try SpeechManager.shared.startRecording()
        } catch {
            isRecording = false
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func stopRecording() {
        SpeechManager.shared.stopRecording()
    }
    
    private func setupSpeechRecognition() {
        // Set up handlers for transcription updates and errors
        SpeechManager.shared.transcriptionHandler = { text in
            DispatchQueue.main.async {
                self.transcribedText = text
            }
        }
        
        SpeechManager.shared.errorHandler = { error in
            DispatchQueue.main.async {
                self.isRecording = false
                self.errorMessage = "Speech recognition error: \(error.localizedDescription)"
                self.showingError = true
            }
        }
    }
    
    private func saveEntry() {
        // Save the entry to local storage using JournalStore
        JournalStore.shared.saveEntry(prompt: currentPrompt, response: transcribedText)
        print("Journal entry saved successfully")
        
        // Move to next prompt or end session
        moveToNextPrompt()
    }
    
    private func discardEntry() {
        // Clear the transcribed text and stay on the same prompt
        transcribedText = ""
        isRecording = false
    }
    
    private func moveToNextPrompt() {
        // Clear the current transcription
        transcribedText = ""
        isRecording = false
        
        // Move to the next prompt or end session
        promptIndex = (promptIndex + 1) % prompts.count
        currentPrompt = prompts[promptIndex]
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
