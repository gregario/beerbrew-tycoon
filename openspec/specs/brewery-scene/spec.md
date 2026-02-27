## ADDED Requirements

### Requirement: Garage brewery scene renders on game start
The system SHALL display a pixel art isometric garage brewery scene when a new run begins. The scene SHALL include a visible player character sprite, 2–3 station slots with pre-placed equipment (kettle, fermenter, bottling station), and a background room that matches a small garage aesthetic.

#### Scenario: Scene loads on game start
- **WHEN** the player starts a new game
- **THEN** the isometric garage brewery scene is visible with all station equipment rendered in their fixed positions

#### Scenario: Player character is present
- **WHEN** the garage scene is active
- **THEN** a player character sprite SHALL be visible standing in the brewery

### Requirement: Station slots are fixed-position and non-interactive in MVP
The system SHALL render station equipment at fixed predefined positions within the garage scene. Players SHALL NOT be able to move, drag, or reposition equipment in the MVP.

#### Scenario: Equipment stays in place
- **WHEN** the player interacts with any game UI
- **THEN** equipment sprites remain at their fixed positions in the scene

### Requirement: Scene provides visual feedback during brewing
The system SHALL display a visual state change on the brewery scene when a brew is in progress (e.g., animated bubbling on the kettle sprite or a progress indicator).

#### Scenario: Brewing in-progress visual
- **WHEN** the player confirms a brew and the brewing phases screen is active
- **THEN** the brewery scene SHALL show at least one animated element indicating active brewing

### Requirement: Brewery scene is readable at target resolution
The system SHALL render the garage scene at a base resolution of 320×180 pixels (pixel art native) scaled to 1920×1080 for display. All sprites SHALL be legible at 1× pixel scale without aliasing.

#### Scenario: Correct pixel art rendering
- **WHEN** the game window is at 1920×1080
- **THEN** all brewery scene sprites render without sub-pixel artifacts or blurring
