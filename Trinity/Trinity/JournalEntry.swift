import Foundation
import SwiftData

@Model
final class JournalEntry {
    var prompt: String
    var response: String
    var timestamp: Date
    var isUploaded: Bool
    
    init(prompt: String, response: String, timestamp: Date, isUploaded: Bool = false) {
        self.prompt = prompt
        self.response = response
        self.timestamp = timestamp
        self.isUploaded = isUploaded
    }
} 
