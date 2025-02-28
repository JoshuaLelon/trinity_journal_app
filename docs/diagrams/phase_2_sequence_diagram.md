```mermaid
sequenceDiagram
    participant User
    participant App
    participant AppleSpeechAPI
    
    User->>App: Opens app
    App->>User: Displays prompt
    App->>AppleSpeechAPI: Starts voice recognition
    AppleSpeechAPI->>App: Returns transcribed text
    App->>User: Displays transcribed text
    User->>App: Decides to re-transcribe
    App->>AppleSpeechAPI: Starts voice recognition again
    AppleSpeechAPI->>App: Returns transcribed text
    App->>User: Displays re-transcribed text
    User->>App: Saves response
    App->>User: Moves to next prompt
``` 