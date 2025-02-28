import Foundation
import Speech
import AVFoundation

class SpeechManager: NSObject, SFSpeechRecognizerDelegate {
    static let shared = SpeechManager()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var transcriptionHandler: ((String) -> Void)?
    var errorHandler: ((Error) -> Void)?
    
    private override init() {
        super.init()
        speechRecognizer?.delegate = self
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            var isAuthorized = false
            
            switch status {
            case .authorized:
                isAuthorized = true
            case .denied, .restricted, .notDetermined:
                isAuthorized = false
            @unknown default:
                isAuthorized = false
            }
            
            DispatchQueue.main.async {
                completion(isAuthorized)
            }
        }
    }
    
    func startRecording() throws {
        // Cancel any ongoing tasks
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure the audio input
        let inputNode = audioEngine.inputNode
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            var isFinal = false
            
            if let result = result {
                // Call the transcription handler with the latest result
                self?.transcriptionHandler?(result.bestTranscription.formattedString)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop audio engine and end recognition
                self?.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
                
                if let error = error {
                    self?.errorHandler?(error)
                }
            }
        }
        
        // Configure the microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start the audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        // Don't cancel the recognition task here to allow it to finish processing
    }
    
    // SFSpeechRecognizerDelegate method
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            // Handle unavailability of speech recognition
            let error = NSError(domain: "SpeechManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognition is not available"])
            errorHandler?(error)
        }
    }
} 