import Foundation

/// Response model for the journal API
public struct JournalResponse: Codable {
    public let detectedPrompt: String
    public let promptChanged: Bool
    public let formattedResponse: String
    public let needsRefinement: Bool
    public let refinementSuggestion: String?
    public let savedToNotion: Bool
    
    public enum CodingKeys: String, CodingKey {
        case detectedPrompt = "detected_prompt"
        case promptChanged = "prompt_changed"
        case formattedResponse = "formatted_response"
        case needsRefinement = "needs_refinement"
        case refinementSuggestion = "refinement_suggestion"
        case savedToNotion = "saved_to_notion"
    }
}

/// ServerAPIClient handles all interactions with the FastAPI server
/// It is implemented as a singleton to ensure consistent API access throughout the app
public class ServerAPIClient {
    // MARK: - Singleton
    public static let shared = ServerAPIClient()
    
    // MARK: - Properties
    private let baseURL = "http://ec2-3-145-81-84.us-east-2.compute.amazonaws.com:8000"
    private let connectionTimeout: TimeInterval = 10.0 // 10 seconds timeout
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - API Methods
    
    /// Process a journal entry
    /// - Parameters:
    ///   - transcription: The transcribed journal entry text
    ///   - currentPrompt: The current prompt type being answered
    ///   - completedPrompts: Array of prompts already completed today
    ///   - completion: Completion handler with response data or error
    public func processJournal(
        transcription: String,
        currentPrompt: String,
        completedPrompts: [String],
        completion: @escaping (JournalResponse?, Error?) -> Void
    ) {
        let url = URL(string: "\(baseURL)/process")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = connectionTimeout
        
        // Create request body
        let requestBody: [String: Any] = [
            "transcription": transcription,
            "current_prompt": currentPrompt,
            "completed_prompts": completedPrompts
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(nil, error)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                // Check for timeout or connection refused errors
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && 
                   (nsError.code == NSURLErrorTimedOut || nsError.code == NSURLErrorCannotConnectToHost) {
                    completion(nil, NSError(domain: "ServerAPIError", code: nsError.code, 
                                           userInfo: [NSLocalizedDescriptionKey: "Cannot connect to server. Please check if the server is running."]))
                } else {
                    completion(nil, error)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, NSError(domain: "ServerAPIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(nil, NSError(domain: "ServerAPIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"]))
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "ServerAPIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(JournalResponse.self, from: data)
                completion(response, nil)
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    /// Get completed prompts for today
    /// - Parameter completion: Completion handler with array of completed prompts or error
    public func getCompletedPrompts(completion: @escaping ([String]?, Error?) -> Void) {
        let url = URL(string: "\(baseURL)/completed-prompts")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = connectionTimeout
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                // Check for timeout or connection refused errors
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && 
                   (nsError.code == NSURLErrorTimedOut || nsError.code == NSURLErrorCannotConnectToHost) {
                    completion(nil, NSError(domain: "ServerAPIError", code: nsError.code, 
                                           userInfo: [NSLocalizedDescriptionKey: "Cannot connect to server. Please check if the server is running."]))
                } else {
                    completion(nil, error)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, NSError(domain: "ServerAPIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                return
            }
            
            // If we get a 500 error from the server, it might be because Notion is not available
            // In this case, return an empty array instead of an error
            if httpResponse.statusCode == 500 {
                print("Warning: Server returned 500 error, likely due to Notion connectivity issues. Returning empty array.")
                completion([], nil)
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(nil, NSError(domain: "ServerAPIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"]))
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "ServerAPIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let completedPrompts = try decoder.decode([String].self, from: data)
                completion(completedPrompts, nil)
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    /// Check if the server is accessible
    /// - Parameter completion: Completion handler with boolean indicating if server is accessible
    public func checkServerConnection(completion: @escaping (Bool) -> Void) {
        let url = URL(string: "\(baseURL)/api/v1/health")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0 // Short timeout for quick check
        
        let task = URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse, 
               (200...499).contains(httpResponse.statusCode) {
                // If we get any HTTP response (even an error), the server is up
                completion(true)
            } else {
                completion(false)
            }
        }
        
        task.resume()
    }
} 