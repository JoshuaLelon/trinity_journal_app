import Foundation
import SwiftUI

// A Codable version of JournalEntry for UserDefaults storage
struct JournalEntryData: Codable {
    let prompt: String
    let response: String
    let timestamp: Date
    let isUploaded: Bool
}

class JournalStore {
    static let shared = JournalStore()
    
    private let userDefaultsKey = "JournalEntries"
    private(set) var entries: [JournalEntryData] = []
    
    // Closure for handling upload status
    var uploadStatusHandler: ((Bool, String) -> Void)?
    
    // Custom URLSession that allows HTTP connections (bypassing ATS)
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        
        // The following line effectively prepares for supporting HTTP
        // This is for development only - in production, use HTTPS
        config.waitsForConnectivity = true
        
        #if DEBUG
        print("⚠️ JournalStore: Using insecure HTTP connection - FOR DEVELOPMENT ONLY ⚠️")
        #endif
        
        return URLSession(configuration: config)
    }()
    
    private init() {
        loadEntries()
    }
    
    func saveEntry(prompt: String, response: String) {
        let newEntry = JournalEntryData(
            prompt: prompt,
            response: response,
            timestamp: Date(),
            isUploaded: false
        )
        entries.append(newEntry)
        saveToUserDefaults()
        
        // After saving locally, try to upload to server
        uploadEntriesToServer()
    }
    
    func getAllEntries() -> [JournalEntryData] {
        return entries
    }
    
    private func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "journalEntries")
        }
    }
    
    // MARK: - Server Integration
    
    /// Uploads all non-uploaded entries to the server
    func uploadEntriesToServer() {
        // Get the current date in ISO format (YYYY-MM-DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        // Get not-yet-uploaded entries
        let notUploadedEntries = entries.filter { !$0.isUploaded }
        
        // If we have entries to upload
        if let latestEntry = notUploadedEntries.last {
            let promptType = mapPromptToType(latestEntry.prompt)
            
            // Get the completed prompts
            let completedPrompts = getCompletedPrompts()
            
            // Process the journal entry through the server
            let url = URL(string: "http://ec2-3-145-81-84.us-east-2.compute.amazonaws.com:8000/process")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10.0
            
            // Create request body
            let requestBody: [String: Any] = [
                "transcription": latestEntry.response,
                "current_prompt": promptType,
                "completed_prompts": completedPrompts
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            } catch {
                DispatchQueue.main.async {
                    self.uploadStatusHandler?(false, "Error creating request: \(error.localizedDescription)")
                }
                return
            }
            
            // Use our custom session instead of URLSession.shared
            let task = session.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let error = error {
                    // Call the handler if set
                    DispatchQueue.main.async {
                        self.uploadStatusHandler?(false, "Error: \(error.localizedDescription)")
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        self.uploadStatusHandler?(false, "Invalid response")
                    }
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    DispatchQueue.main.async {
                        self.uploadStatusHandler?(false, "HTTP Error \(httpResponse.statusCode)")
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        self.uploadStatusHandler?(false, "No data received")
                    }
                    return
                }
                
                do {
                    // Define the response structure inline
                    struct ServerResponse: Decodable {
                        let saved_to_notion: Bool
                    }
                    
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ServerResponse.self, from: data)
                    
                    // Check if saved to Notion
                    let success = response.saved_to_notion
                    
                    if success {
                        // Mark entries as uploaded
                        for i in 0..<self.entries.count {
                            if !self.entries[i].isUploaded {
                                // We can't modify struct properties directly, so we create a new entry
                                let updatedEntry = JournalEntryData(
                                    prompt: self.entries[i].prompt,
                                    response: self.entries[i].response,
                                    timestamp: self.entries[i].timestamp,
                                    isUploaded: true
                                )
                                self.entries[i] = updatedEntry
                            }
                        }
                        
                        // Save to UserDefaults
                        self.saveToUserDefaults()
                    }
                    
                    // Call the handler if set
                    DispatchQueue.main.async {
                        self.uploadStatusHandler?(success, success ? "" : "Failed to save to Notion")
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.uploadStatusHandler?(false, "Error parsing response: \(error.localizedDescription)")
                    }
                }
            }
            
            task.resume()
        }
    }
    
    /// Gets the list of completed prompts
    /// - Returns: Array of completed prompt types
    private func getCompletedPrompts() -> [String] {
        // Simply return the unique prompt types that have been uploaded
        let uploadedEntries = entries.filter { $0.isUploaded }
        let promptTypes = uploadedEntries.map { mapPromptToType($0.prompt) }
        return Array(Set(promptTypes))
    }
    
    /// Maps a prompt to a standardized type for the server
    /// - Parameter prompt: The prompt text
    /// - Returns: A standardized prompt type ("desire", "gratitude", or "brag")
    private func mapPromptToType(_ prompt: String) -> String {
        let lowercasePrompt = prompt.lowercased()
        
        if lowercasePrompt.contains("desire") {
            return "desire"
        } else if lowercasePrompt.contains("grateful") {
            return "gratitude"
        } else if lowercasePrompt.contains("brag") {
            return "brag"
        }
        
        // Default case - if we can't match, use a generic type
        return "note"
    }
    
    private func loadEntries() {
        // Load entries from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "journalEntries"),
           let savedEntries = try? JSONDecoder().decode([JournalEntryData].self, from: data) {
            entries = savedEntries
        }
    }
} 