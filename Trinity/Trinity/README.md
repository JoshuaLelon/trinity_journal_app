# Trinity Journal App

## Overview
Trinity is a voice-first journaling app that uses speech recognition to capture daily reflections based on three core prompts: desires, gratitudes, and brags. The app transcribes your spoken responses and integrates with Notion to store these reflections in a structured format.

## Core Components

### Managers
- **SpeechManager**: Handles speech recognition and transcription
- **NotificationManager**: Manages daily reminders
- **JournalStore**: Stores journal entries locally and syncs with Notion

### Models
- **JournalEntry**: Represents a single response to a prompt
- **JournalEntryData**: Codable version for storage

### Integration
- **NotionAPIClient**: Handles all Notion API interactions

## Notion Integration
The app integrates with Notion to store journal entries in a structured database:

1. **Finding the Daily Page**: The app looks for a page titled "Daily: @Today" in your Notion database
2. **Structured Data**: Each prompt type is stored in its respective field (desires, gratitudes, brags)
3. **Error Handling**: Provides feedback for success/failure of Notion operations
4. **Retry Mechanism**: Allows retrying failed uploads

### API Contract
The app uses the following Notion API endpoints:
- `POST /v1/databases/{database_id}/query` - To find the Daily page
- `PATCH /v1/pages/{page_id}` - To update the Daily page with journal entries

## Getting Started
To use the Notion integration:

1. Obtain a Notion API key from the [Notion Integrations page](https://www.notion.so/my-integrations)
2. Ensure your Notion database has a page titled "Daily: @Today" with the following properties:
   - "desires" (rich text property)
   - "gratitudes" (rich text property)
   - "brags" (rich text property)
3. Share the database with your integration
4. Update the API key using the secure storage system

## Security Considerations
The app uses the following security measures:
- Keychain Services API for securely storing the Notion API key
- No hardcoded API keys in the source code
- Clear separation of credential storage from business logic 