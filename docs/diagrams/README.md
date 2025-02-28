# Diagrams Directory

This directory contains all the diagrams used throughout the Trinity Journaling App documentation. Diagrams are organized by phase and type to improve maintainability and readability of the main documentation files.

## Directory Structure

### Phase 1 Diagrams
- [Phase 1 Sequence Diagram](./phase_1_sequence_diagram.md) - Shows the interaction flow between the user, app, and Apple Speech API in Phase 1
- [Phase 1 Flow Diagram](./phase_1_flow_diagram.md) - Illustrates the overall process flow for the basic journaling functionality

### Phase 2 Diagrams
- [Phase 2 Sequence Diagram](./phase_2_sequence_diagram.md) - Shows the enhanced interaction flow with auto-start recording
- [Phase 2 Flow Diagram](./phase_2_flow_diagram.md) - Illustrates the process flow with automatic recording and improved UI

### Phase 3 Diagrams
- [Phase 3 Sequence Diagram](./phase_3_sequence_diagram.md) - Shows the interaction flow with Notion API integration
- [Phase 3 Flow Diagram](./phase_3_flow_diagram.md) - Illustrates the process flow with Notion storage capabilities

### Phase 4 Diagrams
- [Phase 4 Sequence Diagram](./phase_4_sequence_diagram.md) - Shows the interaction flow with AI-powered prompt classification
- [Phase 4 Flow Diagram](./phase_4_flow_diagram.md) - Illustrates the enhanced process flow with AI capabilities
- [Phase 4 LangGraph Flow Diagram](./phase_4_langgraph_flow_diagram.md) - Details the backend LangGraph workflow for AI processing

## Diagram Types

### Sequence Diagrams
Sequence diagrams show the interactions between different components (user, app, APIs) over time. They help visualize the order of operations and message passing between system components.

### Flow Diagrams
Flow diagrams (flowcharts) illustrate the overall process flow of the application, showing decision points, actions, and the general path a user takes through the application.

### LangGraph Flow Diagram
The LangGraph flow diagram specifically illustrates the backend AI workflow built with LangGraph, showing how user responses are processed, classified, and formatted before being stored in Notion. 