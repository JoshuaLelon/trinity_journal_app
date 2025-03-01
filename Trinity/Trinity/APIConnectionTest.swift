import SwiftUI
import Foundation

struct APIConnectionTest: View {
    @State private var serverStatus: String = "Checking..."
    @State private var isLoading: Bool = false
    @State private var lastError: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("API Connection Test")
                .font(.largeTitle)
                .padding(.top)
            
            // FastAPI Server Status
            VStack(alignment: .leading, spacing: 10) {
                Text("FastAPI Server Status:")
                    .font(.headline)
                
                HStack {
                    Text(serverStatus)
                        .foregroundColor(serverStatusColor)
                    
                    if isLoading {
                        ProgressView()
                            .padding(.leading)
                    }
                }
                
                if let error = lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
                
                Button("Test Server Connection") {
                    checkServerConnection()
                }
                .disabled(isLoading)
                
                Text("The server at ec2-3-145-81-84.us-east-2.compute.amazonaws.com:8000 handles all API calls, including saving to Notion")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear {
            checkServerConnection()
        }
    }
    
    // MARK: - Computed Properties
    
    private var serverStatusColor: Color {
        if serverStatus == "Connected" {
            return .green
        } else if serverStatus == "Checking..." {
            return .gray
        } else {
            return .red
        }
    }
    
    // MARK: - Methods
    
    private func checkServerConnection() {
        isLoading = true
        serverStatus = "Checking..."
        lastError = nil
        
        // First try the health endpoint
        checkHealthEndpoint { success, error in
            if success {
                DispatchQueue.main.async {
                    isLoading = false
                    serverStatus = "Connected"
                }
            } else {
                // If health endpoint fails, try the completed-prompts endpoint as fallback
                checkCompletedPromptsEndpoint { success, error in
                    DispatchQueue.main.async {
                        isLoading = false
                        if success {
                            serverStatus = "Connected"
                        } else {
                            serverStatus = "Not Connected"
                            lastError = error
                        }
                    }
                }
            }
        }
    }
    
    private func checkHealthEndpoint(completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "http://ec2-3-145-81-84.us-east-2.compute.amazonaws.com:8000/api/v1/health")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0 // Short timeout for quick check
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(false, "Error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    completion(true, nil)
                } else {
                    completion(false, "HTTP Error: \(httpResponse.statusCode)")
                }
            } else {
                completion(false, "Server may be down or unreachable")
            }
        }
        
        task.resume()
    }
    
    private func checkCompletedPromptsEndpoint(completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "http://ec2-3-145-81-84.us-east-2.compute.amazonaws.com:8000/completed-prompts")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0 // Short timeout for quick check
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(false, "Error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    completion(true, nil)
                } else {
                    completion(false, "HTTP Error: \(httpResponse.statusCode)")
                }
            } else {
                completion(false, "Server may be down or unreachable")
            }
        }
        
        task.resume()
    }
}

#Preview {
    APIConnectionTest()
} 