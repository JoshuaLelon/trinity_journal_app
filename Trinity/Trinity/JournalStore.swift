import Foundation
// Import the NotionAPIClient module
import SwiftUI // This is needed to give access to our app's modules

// A Codable version of JournalEntry for UserDefaults storage
struct JournalEntryData: Codable {
    let prompt: String
    let response: String
    let timestamp: Date
    let isUploaded: Bool
}

class JournalStore {
    static let shared = JournalStore()
    
    private var entries: [JournalEntryData] = []
    
    // Closure for handling Notion upload status
    var notionUploadStatusHandler: ((Bool, String?) -> Void)?
    
    private init() {
        // Load entries from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "journalEntries"),
           let savedEntries = try? JSONDecoder().decode([JournalEntryData].self, from: data) {
            entries = savedEntries
        }
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
        
        // After saving locally, try to upload to Notion
        uploadEntriesToNotion()
    }
    
    func getAllEntries() -> [JournalEntryData] {
        return entries
    }
    
    private func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "journalEntries")
        }
    }
    
    // MARK: - Notion Integration
    
    /// Uploads all non-uploaded entries to Notion
    func uploadEntriesToNotion() {
        // Get the current date in ISO format (YYYY-MM-DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        // Organize entries by prompt type
        var promptData: [String: [String]] = [:]
        
        // Group not-yet-uploaded entries by prompt type
        let notUploadedEntries = entries.filter { !$0.isUploaded }
        
        for entry in notUploadedEntries {
            let promptType = mapPromptToType(entry.prompt)
            if promptData[promptType] == nil {
                promptData[promptType] = []
            }
            promptData[promptType]?.append(entry.response)
        }
        
        // If we have entries to upload
        if !promptData.isEmpty {
            NotionAPIClient.shared.sendEntry(date: today, promptData: promptData) { [weak self] success, errorMessage in
                guard let self = self else { return }
                
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
                    self.saveToUserDefaults()
                }
                
                // Call the handler if set
                DispatchQueue.main.async {
                    self.notionUploadStatusHandler?(success, errorMessage)
                }
            }
        }
    }
    
    /// Maps a prompt to a standardized type for Notion
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
} 