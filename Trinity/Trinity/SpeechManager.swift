import Foundation
import Speech
import AVFoundation
import os.log

class SpeechManager: NSObject, SFSpeechRecognizerDelegate {
    static let shared = SpeechManager()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var noSpeechTimer: Timer?
    private var isListening = false
    private var isCleaningUp = false
    private var lastSessionEndTime: Date?
    private var taskCompletionTimer: Timer?
    private var isCancelling = false
    
    // Create a logger with the subsystem as your app's bundle ID
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.trinity.journal", category: "SpeechManager")
    
    var transcriptionHandler: ((String) -> Void)?
    var errorHandler: ((Error) -> Void)?
    
    private override init() {
        super.init()
        speechRecognizer?.delegate = self
        logger.info("SpeechManager initialized")
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        logger.info("Requesting speech recognition permissions")
        SFSpeechRecognizer.requestAuthorization { status in
            var isAuthorized = false
            
            switch status {
            case .authorized:
                isAuthorized = true
                self.logger.info("Speech recognition permission granted")
            case .denied:
                isAuthorized = false
                self.logger.error("Speech recognition permission denied")
            case .restricted:
                isAuthorized = false
                self.logger.error("Speech recognition permission restricted")
            case .notDetermined:
                isAuthorized = false
                self.logger.error("Speech recognition permission not determined")
            @unknown default:
                isAuthorized = false
                self.logger.error("Speech recognition permission unknown status")
            }
            
            DispatchQueue.main.async {
                completion(isAuthorized)
            }
        }
    }
    
    func startRecording() throws {
        logger.info("Starting recording")
        
        // Check if we need to wait before starting a new session
        if let lastEnd = lastSessionEndTime {
            let timeSinceLastSession = Date().timeIntervalSince(lastEnd)
            let minimumWaitTime: TimeInterval = 3.0 // Increased to 3 seconds between sessions
            
            if timeSinceLastSession < minimumWaitTime {
                let waitTime = minimumWaitTime - timeSinceLastSession
                logger.info("Need to wait \(waitTime) seconds before starting a new session")
                Thread.sleep(forTimeInterval: waitTime)
            }
        }
        
        // Prevent multiple simultaneous recording sessions
        if isListening {
            logger.warning("Already listening, stopping current session first")
            stopRecording()
            
            // Wait for cleanup to complete before starting a new session
            if isCleaningUp {
                logger.info("Waiting for cleanup to complete")
                Thread.sleep(forTimeInterval: 3.0) // Increased to 3 seconds
            }
        }
        
        // Ensure we're not in a cleanup state
        if isCleaningUp {
            logger.info("Still cleaning up, waiting before starting new session")
            Thread.sleep(forTimeInterval: 3.0) // Increased to 3 seconds
        }
        
        // Ensure we're not in the process of cancelling a task
        if isCancelling {
            logger.info("Still cancelling previous task, waiting before starting new session")
            Thread.sleep(forTimeInterval: 2.0)
        }
        
        isListening = true
        
        // Cancel any ongoing tasks
        if recognitionTask != nil {
            logger.info("Cancelling existing recognition task")
            isCancelling = true
            recognitionTask?.cancel()
            recognitionTask = nil
            
            // Add a small delay after cancellation
            Thread.sleep(forTimeInterval: 1.0) // Increased to 1 second
            isCancelling = false
        }
        
        // Ensure audio engine is stopped before starting a new session
        if audioEngine.isRunning {
            logger.warning("Audio engine was already running, stopping it first")
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            
            // Add a small delay after stopping the audio engine
            Thread.sleep(forTimeInterval: 1.0) // Increased to 1 second
        }
        
        // Configure audio session - only on iOS
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            logger.info("Setting up audio session")
            try audioSession.setCategory(.record, mode: .default, options: [.duckOthers, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            logger.info("Audio session successfully configured")
        } catch {
            logger.error("Failed to set up audio session: \(error.localizedDescription)")
            isListening = false
            throw error
        }
        #else
        logger.info("Audio session setup skipped (not on iOS)")
        #endif
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            let error = NSError(domain: "SpeechManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
            logger.error("Failed to create recognition request: \(error.localizedDescription)")
            isListening = false
            throw error
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Set task constraints to improve recognition
        if #available(iOS 13, macOS 10.15, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
            recognitionRequest.taskHint = .dictation
        }
        
        // Configure the audio input
        let inputNode = audioEngine.inputNode
        
        // Start recognition
        logger.info("Starting speech recognition task")
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                // Reset no speech timer when we get results
                self.resetNoSpeechTimer()
                
                // Call the transcription handler with the latest result
                self.transcriptionHandler?(result.bestTranscription.formattedString)
                isFinal = result.isFinal
                
                if isFinal {
                    self.logger.info("Received final transcription result")
                }
            }
            
            if error != nil || isFinal {
                // Stop audio engine and end recognition
                self.logger.info("Stopping audio engine due to error or final result")
                self.cleanupAudioSession()
                
                if let error = error {
                    self.logger.error("Speech recognition error: \(error.localizedDescription)")
                    
                    // Check for "no speech detected" error
                    let nsError = error as NSError
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1101 {
                        // This is a common error when there's no speech detected or when sessions overlap
                        // We'll handle it silently since we already have the no speech timer
                        self.logger.info("Received kAFAssistantErrorDomain error - handling silently")
                    } else if error.localizedDescription == "Recognition request was canceled" {
                        // Ignore cancellation errors as they're expected during normal operation
                        self.logger.info("Recognition request was canceled (expected behavior)")
                    } else {
                        // For other errors, notify the handler
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.errorHandler?(error)
                        }
                    }
                }
            }
        }
        
        // Set a task completion timer to ensure the task doesn't hang
        startTaskCompletionTimer()
        
        // Configure the microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        logger.info("Installing tap on input node")
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start the audio engine
        logger.info("Preparing audio engine")
        audioEngine.prepare()
        
        do {
            logger.info("Starting audio engine")
            try audioEngine.start()
            logger.info("Audio engine started successfully")
            
            // Start a timer to detect if no speech is happening
            startNoSpeechTimer()
            
        } catch {
            logger.error("Failed to start audio engine: \(error.localizedDescription)")
            cleanupAudioSession()
            throw error
        }
    }
    
    func stopRecording() {
        // Prevent multiple stop calls
        if isCleaningUp {
            logger.info("Already cleaning up, ignoring duplicate stop call")
            return
        }
        
        logger.info("Stopping recording")
        isCleaningUp = true
        
        // Cancel the no speech timer
        invalidateNoSpeechTimer()
        
        // Cancel the task completion timer
        invalidateTaskCompletionTimer()
        
        if audioEngine.isRunning {
            logger.info("Audio engine is running, stopping it")
            audioEngine.stop()
            
            // Remove the tap on the input node
            if audioEngine.inputNode.numberOfInputs > 0 {
                logger.info("Removing tap from input node")
                audioEngine.inputNode.removeTap(onBus: 0)
            }
            
            logger.info("Ending audio for recognition request")
            recognitionRequest?.endAudio()
        } else {
            logger.warning("Attempted to stop recording but audio engine was not running")
        }
        
        // Reset the audio session on iOS
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            logger.info("Audio session deactivated")
        } catch {
            logger.error("Failed to deactivate audio session: \(error.localizedDescription)")
        }
        #endif
        
        // Record when we ended this session
        lastSessionEndTime = Date()
        
        // Cancel the recognition task after a longer delay to allow processing to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            self.logger.info("Cancelling existing recognition task")
            self.isCancelling = true
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
            self.recognitionRequest = nil
            
            // Add a delay before marking cancellation as complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isCancelling = false
                self.isListening = false
                self.isCleaningUp = false
                self.logger.info("Recognition task and request cleared")
            }
        }
    }
    
    // Helper method to clean up audio session
    private func cleanupAudioSession() {
        isCleaningUp = true
        
        invalidateNoSpeechTimer()
        invalidateTaskCompletionTimer()
        
        audioEngine.stop()
        
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest = nil
        
        // Reset the audio session on iOS
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            logger.error("Failed to deactivate audio session: \(error.localizedDescription)")
        }
        #endif
        
        // Record when we ended this session
        lastSessionEndTime = Date()
        
        // Set a delay before marking cleanup as complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isCleaningUp = false
            self?.isListening = false
        }
    }
    
    // Start a timer to detect if no speech is happening
    private func startNoSpeechTimer() {
        invalidateNoSpeechTimer()
        
        // Set a timer for 5 seconds - if no speech is detected in this time, we'll notify
        noSpeechTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            self.logger.warning("No speech detected after timeout")
            
            // Only report no speech if we're still listening
            if self.isListening {
                // First, properly clean up the audio session
                self.stopRecording()
                
                // Then report the error after a delay to ensure cleanup is complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    let noSpeechError = NSError(domain: "SpeechManager", code: 3, 
                                               userInfo: [NSLocalizedDescriptionKey: "No speech detected"])
                    self.errorHandler?(noSpeechError)
                }
            }
        }
    }
    
    // Start a timer to ensure the recognition task completes
    private func startTaskCompletionTimer() {
        invalidateTaskCompletionTimer()
        
        // Set a timer for 30 seconds - if the task hasn't completed by then, force completion
        taskCompletionTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            self.logger.warning("Recognition task timed out after 30 seconds")
            
            // Only force completion if we're still listening
            if self.isListening {
                self.stopRecording()
            }
        }
    }
    
    // Reset the no speech timer when we get speech
    private func resetNoSpeechTimer() {
        startNoSpeechTimer()
    }
    
    // Invalidate the no speech timer
    private func invalidateNoSpeechTimer() {
        noSpeechTimer?.invalidate()
        noSpeechTimer = nil
    }
    
    // Invalidate the task completion timer
    private func invalidateTaskCompletionTimer() {
        taskCompletionTimer?.invalidate()
        taskCompletionTimer = nil
    }
    
    // SFSpeechRecognizerDelegate method
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            // Handle unavailability of speech recognition
            logger.error("Speech recognition became unavailable")
            let error = NSError(domain: "SpeechManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognition is not available"])
            errorHandler?(error)
        } else {
            logger.info("Speech recognition became available")
        }
    }
} 