import Foundation

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
    }
    
    func getAllEntries() -> [JournalEntryData] {
        return entries
    }
    
    private func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "journalEntries")
        }
    }
} 