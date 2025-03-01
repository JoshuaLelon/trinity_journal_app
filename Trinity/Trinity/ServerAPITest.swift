import Foundation
import SwiftUI

struct ServerAPITest: View {
    @State private var transcription: String = ""
    @State private var currentPrompt: String = "gratitude"
    @State private var completedPrompts: [String] = []
    @State private var formattedResponse: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var savedToNotion: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Server API Test")
                .font(.largeTitle)
                .padding(.top)
            
            // Prompt selection
            Picker("Prompt", selection: $currentPrompt) {
                Text("Gratitude").tag("gratitude")
                Text("Desire").tag("desire")
                Text("Brag").tag("brag")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Journal entry input
            TextEditor(text: $transcription)
                .frame(height: 200)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .padding()
            
            // Submit button
            Button(action: processJournalEntry) {
                Text("Process Journal Entry")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            .disabled(isLoading)
            
            // Loading indicator
            if isLoading {
                ProgressView()
                    .padding()
            }
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Response status
            if !formattedResponse.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Formatted Response:")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(savedToNotion ? "Saved to Notion ✓" : "Not saved to Notion ✗")
                            .foregroundColor(savedToNotion ? .green : .red)
                            .font(.caption)
                    }
                    
                    Text(formattedResponse)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadCompletedPrompts()
        }
    }
    
    // MARK: - Methods
    
    /// Process the current journal entry
    private func processJournalEntry() {
        guard !transcription.isEmpty else {
            errorMessage = "Please enter a journal entry"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Use the API directly
        let url = URL(string: "http://ec2-3-145-81-84.us-east-2.compute.amazonaws.com:8000/process")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        // Create request body
        let requestBody: [String: Any] = [
            "transcription": transcription,
            "current_prompt": currentPrompt,
            "completed_prompts": completedPrompts
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            isLoading = false
            errorMessage = "Error creating request: \(error.localizedDescription)"
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response"
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    errorMessage = "HTTP Error \(httpResponse.statusCode)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                do {
                    // Define the response structure inline
                    struct ServerResponse: Decodable {
                        let detected_prompt: String
                        let prompt_changed: Bool
                        let formatted_response: String
                        let needs_refinement: Bool
                        let refinement_suggestion: String?
                        let saved_to_notion: Bool
                    }
                    
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ServerResponse.self, from: data)
                    
                    // Update state with response data
                    formattedResponse = response.formatted_response
                    savedToNotion = response.saved_to_notion
                    
                    // If the prompt was changed, update it
                    if response.prompt_changed {
                        currentPrompt = response.detected_prompt
                    }
                    
                    // If saved to Notion and not in completed prompts, add it
                    if response.saved_to_notion && !completedPrompts.contains(response.detected_prompt) {
                        completedPrompts.append(response.detected_prompt)
                    }
                } catch {
                    errorMessage = "Error parsing response: \(error.localizedDescription)"
                }
            }
        }
        
        task.resume()
    }
    
    /// Load the list of completed prompts for today
    private func loadCompletedPrompts() {
        isLoading = true
        
        // Use the API directly
        let url = URL(string: "http://ec2-3-145-81-84.us-east-2.compute.amazonaws.com:8000/completed-prompts")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Error loading completed prompts: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response"
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    errorMessage = "HTTP Error \(httpResponse.statusCode)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    completedPrompts = try decoder.decode([String].self, from: data)
                } catch {
                    errorMessage = "Error parsing response: \(error.localizedDescription)"
                }
            }
        }
        
        task.resume()
    }
}

#Preview {
    ServerAPITest()
} 