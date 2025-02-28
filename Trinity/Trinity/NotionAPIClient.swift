import Foundation
import Security

/// NotionAPIClient handles all interactions with the Notion API
/// It is implemented as a singleton to ensure consistent API access throughout the app
class NotionAPIClient {
    // MARK: - Singleton
    static let shared = NotionAPIClient()
    
    // MARK: - Properties
    private let baseURL = "https://api.notion.com/v1"
    private var apiKey: String = ""
    private var databaseId: String = "dfe40ba98b8f4b31a3e6825cadcec46b" // Use the provided database ID
    
    // MARK: - Initialization
    private init() {
        // Load API key from secure storage
        loadConfiguration()
    }
    
    // MARK: - Configuration
    private func loadConfiguration() {
        // IMPORTANT: In a production app, the API key should be stored securely
        // Options include:
        // 1. Using Keychain Services API
        // 2. Loading from environment variables
        // 3. Using a backend service for API calls
        
        // For development, you can set your API key here
        // but replace this with secure storage before production
        self.apiKey = "" // Deliberately empty - set your key through secure means
        
        // For testing purposes, you could uncomment and set your key directly:
        // self.apiKey = "your_key_here" 
        
        // TODO: Implement proper secure storage - e.g., using Keychain:
        // self.apiKey = retrieveKeyFromKeychain() ?? ""
    }
    
    // MARK: - API Methods
    
    /// Sends a journal entry to Notion
    /// - Parameters:
    ///   - date: The date of the journal entry
    ///   - promptData: Dictionary mapping prompt types to arrays of responses
    ///   - completion: Completion handler called with success status and optional error message
    func sendEntry(date: String, promptData: [String: [String]], completion: @escaping (Bool, String?) -> Void) {
        // Find the daily page - we assume it exists with the name "Daily: @Today"
        findDailyPage { [weak self] pageId, error in
            guard let self = self, let pageId = pageId else {
                completion(false, error ?? "Failed to find the Daily page")
                return
            }
            
            // Update the page with the new prompt data
            self.updatePage(pageId: pageId, promptData: promptData, completion: completion)
        }
    }
    
    /// Finds the daily note page in Notion
    /// - Parameters:
    ///   - completion: Completion handler with the page ID or error
    private func findDailyPage(completion: @escaping (String?, String?) -> Void) {
        // Query the database for the page with title "Daily: @Today"
        let queryURL = URL(string: "\(baseURL)/databases/\(databaseId)/query")!
        
        var request = URLRequest(url: queryURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version") // Use current API version
        
        // Create filter to find the Daily page
        let requestData: [String: Any] = [
            "filter": [
                "property": "title",
                "title": [
                    "contains": "Daily: @Today"
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            completion(nil, "Error creating request: \(error.localizedDescription)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, "Network error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, "Invalid response")
                return
            }
            
            if httpResponse.statusCode != 200 {
                completion(nil, "API error: HTTP \(httpResponse.statusCode)")
                return
            }
            
            guard let data = data else {
                completion(nil, "No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    
                    if let firstPage = results.first, 
                       let id = firstPage["id"] as? String {
                        // Found the Daily page
                        completion(id, nil)
                    } else {
                        // Daily page not found
                        completion(nil, "Daily page not found. Please ensure a page with title 'Daily: @Today' exists in your Notion database.")
                    }
                }
            } catch {
                completion(nil, "Error parsing response: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    /// Updates a Notion page with prompt data
    /// - Parameters:
    ///   - pageId: The ID of the page to update
    ///   - promptData: Dictionary mapping prompt types to arrays of responses
    ///   - completion: Completion handler called with success status and optional error message
    private func updatePage(pageId: String, promptData: [String: [String]], completion: @escaping (Bool, String?) -> Void) {
        let updateURL = URL(string: "\(baseURL)/pages/\(pageId)")!
        
        var request = URLRequest(url: updateURL)
        request.httpMethod = "PATCH"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        
        // Build the properties to update based on the promptData
        var properties: [String: Any] = [:]
        
        // Map the prompt types to Notion property names (lowercase as specified)
        if let desires = promptData["desire"] {
            properties["desires"] = createRichTextProperty(from: desires)
        }
        
        if let gratitudes = promptData["gratitude"] {
            properties["gratitudes"] = createRichTextProperty(from: gratitudes)
        }
        
        if let brags = promptData["brag"] {
            properties["brags"] = createRichTextProperty(from: brags)
        }
        
        let requestData: [String: Any] = ["properties": properties]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            completion(false, "Error creating request: \(error.localizedDescription)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "Network error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "Invalid response")
                return
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                completion(false, "API error: HTTP \(httpResponse.statusCode)")
                return
            }
            
            // Successfully updated the page
            completion(true, nil)
        }
        
        task.resume()
    }
    
    // MARK: - Helper Methods
    
    /// Creates a rich text property from an array of strings
    /// - Parameter texts: Array of text strings
    /// - Returns: Dictionary representing a Notion rich text property
    private func createRichTextProperty(from texts: [String]) -> [String: Any] {
        let richTextArray = texts.map { text -> [String: Any] in
            return ["text": ["content": text]]
        }
        
        return ["rich_text": richTextArray]
    }
    
    // MARK: - Keychain Methods (for secure API key storage)
    
    /// Retrieves the API key from the keychain
    /// - Returns: The API key, or nil if not found
    private func retrieveKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.trinity.journal.notionapi",
            kSecAttrAccount as String: "notionApiKey",
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    /// Saves the API key to the keychain
    /// - Parameter key: The API key to save
    /// - Returns: Whether the operation was successful
    private func saveKeyToKeychain(key: String) -> Bool {
        guard let data = key.data(using: .utf8) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.trinity.journal.notionapi",
            kSecAttrAccount as String: "notionApiKey",
            kSecValueData as String: data
        ]
        
        // First try to update an existing item
        var status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        
        // If the item doesn't exist, add it
        if status == errSecItemNotFound {
            status = SecItemAdd(query as CFDictionary, nil)
        }
        
        return status == errSecSuccess
    }
} 