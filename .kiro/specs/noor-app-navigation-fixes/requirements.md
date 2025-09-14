# Noor App Navigation and Flow Fixes Requirements

## Introduction

This specification addresses critical navigation, app flow, and user experience issues in the Noor learning app. The primary focus is fixing the main app entry point, unifying chat interfaces, implementing proper navigation controls, and creating a cohesive user experience that properly integrates the AI chat functionality with the student dashboard and learning features.

## Requirements

### Requirement 1: Fix Main App Entry Point and Flow

**User Story:** As a user, I want the app to start with the student dashboard as the main screen, so that I can access all learning features from a central hub rather than being dropped into a model checking screen.

#### Acceptance Criteria

1. WHEN the app starts THEN the system SHALL route directly to StudentDashboardScreen instead of ModelCheckWrapper
2. WHEN the app initializes THEN local model checking SHALL happen in the background without blocking app access
3. WHEN the app starts THEN AI chat SHALL be immediately available using online AI service
4. WHEN local model download is in progress THEN the user SHALL see a progress indicator but can still use online AI features
5. IF local model download fails THEN the system SHALL continue using online AI service without disrupting user experience
6. WHEN the local model is ready THEN the system SHALL optionally switch to local inference for better privacy and offline capability

### Requirement 2: Implement Proper Navigation Architecture

**User Story:** As a user, I want consistent navigation throughout the app with clear ways to move between features, so that I never feel trapped in any single screen.

#### Acceptance Criteria

1. WHEN using any screen THEN the system SHALL provide clear navigation controls (back button, menu, or tab navigation)
2. WHEN in the AI chat screen THEN the user SHALL have access to navigation controls to return to the dashboard
3. WHEN navigating between features THEN the system SHALL maintain proper navigation stack and state
4. IF the user is deep in a feature THEN they SHALL always have a way to return to the main dashboard
5. WHEN using bottom navigation THEN all tabs SHALL be accessible from any screen

### Requirement 3: Unify Chat Interface Implementation

**User Story:** As a developer, I want a single, consistent chat interface implementation, so that there's no confusion between different chat screens and all chat functionality uses the same underlying service.

#### Acceptance Criteria

1. WHEN implementing chat features THEN the system SHALL use only one chat interface (either GemmaChatPage or AiChatScreen, not both)
2. WHEN a user accesses AI chat THEN they SHALL always get the same interface regardless of entry point
3. WHEN chat functionality is updated THEN changes SHALL apply consistently across the entire app
4. IF there are duplicate chat implementations THEN the system SHALL remove the redundant code
5. WHEN chat services are called THEN all interfaces SHALL use the same FlutterGemmaService

### Requirement 4: Integrate AI Chat as Navigation Tab

**User Story:** As a user, I want AI chat to be one tab in the bottom navigation, so that I can easily switch between chat, dashboard, courses, and other features.

#### Acceptance Criteria

1. WHEN viewing the main app interface THEN AI chat SHALL appear as one tab in the bottom navigation bar
2. WHEN switching to the chat tab THEN the user SHALL see the full chat interface without losing navigation context
3. WHEN in chat mode THEN other navigation tabs SHALL remain accessible for quick switching
4. IF the AI model is not ready THEN the chat tab SHALL show a loading or unavailable state
5. WHEN receiving chat responses THEN navigation to other tabs SHALL not interrupt ongoing conversations

### Requirement 5: Create Proper Onboarding Flow

**User Story:** As a new user, I want a clear onboarding experience that explains the app features and guides me through initial setup, so that I understand how to use the learning platform effectively.

#### Acceptance Criteria

1. WHEN a user opens the app for the first time THEN the system SHALL show a welcome screen explaining the app's purpose
2. WHEN onboarding begins THEN the user SHALL be guided through key features including courses, AI chat, and achievements
3. WHEN model download is required THEN the onboarding SHALL explain the AI features and show download progress
4. IF the user skips onboarding THEN they SHALL still be able to access it later from settings
5. WHEN onboarding is complete THEN the user SHALL be taken to the main dashboard with clear next steps

### Requirement 6: Fix FlutterGemma Service Integration

**User Story:** As a user, I want the AI chat to provide real responses from the FlutterGemma model instead of placeholder text, so that I can have meaningful conversations with the AI tutor.

#### Acceptance Criteria

1. WHEN a user sends a message to the AI THEN the system SHALL return actual AI-generated responses from FlutterGemma
2. WHEN the FlutterGemma service processes a request THEN it SHALL use the properly loaded Gemma model for inference
3. WHEN streaming responses are enabled THEN the user SHALL see real-time token generation from the AI model
4. IF the AI service fails THEN the system SHALL provide clear error messages and recovery options
5. WHEN the model is not loaded THEN the system SHALL handle this gracefully with appropriate user feedback
6. WHEN using the AI THEN all processing SHALL happen on-device using FlutterGemma for privacy and offline capability

### Requirement 7: Implement Missing CourseContextService

**User Story:** As a developer, I want the CourseContextService to be properly implemented, so that the app builds successfully and course-related features work correctly.

#### Acceptance Criteria

1. WHEN the app builds THEN there SHALL be no missing class errors for CourseContextService
2. WHEN course features are accessed THEN the CourseContextService SHALL provide proper context tracking
3. WHEN AI chat references courses THEN it SHALL use CourseContextService to understand user progress
4. IF course context is needed THEN the service SHALL provide relevant course information
5. WHEN integrating with existing course system THEN the service SHALL connect properly with course data

### Requirement 8: Connect Achievement System to UI

**User Story:** As a user, I want to see achievement notifications and progress when I earn them through AI interactions, so that I feel rewarded for my learning progress.

#### Acceptance Criteria

1. WHEN the AI awards an achievement THEN the user SHALL see a visible notification or popup
2. WHEN achievements are earned THEN they SHALL be properly recorded and displayed in the user interface
3. WHEN viewing achievements THEN the user SHALL see progress indicators and descriptions
4. IF multiple achievements are earned THEN the system SHALL handle notifications appropriately
5. WHEN achievement progress changes THEN the UI SHALL update to reflect the current status

### Requirement 9: Improve Local Model Download User Experience

**User Story:** As a user, I want a better experience when the local AI model is being downloaded, so that I understand what's happening while continuing to use AI features through the online service.

#### Acceptance Criteria

1. WHEN local model download begins THEN the user SHALL see a clear progress indicator with percentage completion
2. WHEN download is in progress THEN the user SHALL continue using AI features through the online service
3. WHEN download completes THEN the user SHALL be notified that offline AI features are now available
4. IF download fails THEN the user SHALL see clear error messages with retry options while online AI remains functional
5. WHEN retrying download THEN the system SHALL resume from where it left off if possible
6. WHEN local model is available THEN the user SHALL have settings to choose between online and local AI modes

### Requirement 10: Improve FlutterGemma Model Download Experience

**User Story:** As a user, I want a better experience when the FlutterGemma model is being downloaded, so that I understand what's happening and can continue using other app features.

#### Acceptance Criteria

1. WHEN model download begins THEN the user SHALL see a clear progress indicator with percentage completion
2. WHEN download is in progress THEN the user SHALL be able to access non-AI features of the app
3. WHEN download completes THEN the user SHALL be notified that AI features are now available
4. IF download fails THEN the user SHALL see clear error messages with retry options
5. WHEN retrying download THEN the system SHALL resume from where it left off if possible
6. WHEN the model is ready THEN the AI chat SHALL seamlessly become fully functional

### Requirement 11: Ensure Consistent App State Management

**User Story:** As a user, I want the app to maintain consistent state when switching between features, so that my progress and context are preserved across navigation.

#### Acceptance Criteria

1. WHEN switching between navigation tabs THEN the app SHALL preserve the state of each tab
2. WHEN returning to a previous screen THEN the user SHALL see the same content and scroll position
3. WHEN the app is backgrounded and restored THEN all state SHALL be properly maintained
4. IF the app crashes or restarts THEN critical user data and progress SHALL be preserved
5. WHEN using AI chat THEN conversation history SHALL be maintained across navigation changes