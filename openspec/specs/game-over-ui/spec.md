## ADDED Requirements

### Requirement: Game over screen is shown on win or loss
The system SHALL display a dedicated end-of-run screen when either a win condition or a loss condition is triggered. The screen SHALL clearly distinguish between a win state and a loss state.

#### Scenario: Win state shown on milestone reached
- **WHEN** the player's balance reaches or exceeds the win target
- **THEN** the game over screen is shown with a win message and visual treatment

#### Scenario: Loss state shown on bankruptcy
- **WHEN** a loss condition is triggered (balance ≤ 0 or can't afford next brew)
- **THEN** the game over screen is shown with a loss message and visual treatment

### Requirement: Game over screen displays final run statistics
The system SHALL display the following stats on the end-of-run screen: total turns (brews) completed, best single-brew quality score achieved, total revenue earned across the run, and final cash balance.

#### Scenario: All stats visible
- **WHEN** the game over screen is shown
- **THEN** total turns, best quality score, total revenue, and final balance are all displayed

### Requirement: Player can start a new run from the game over screen
The system SHALL provide a "New Run" or "Play Again" button on the game over screen that resets all run state and starts a new game from the beginning (garage scene, starting balance, turn 1).

#### Scenario: New run resets state
- **WHEN** the player presses "New Run" on the game over screen
- **THEN** all run state is reset: balance returns to starting amount, turn counter resets to 0, recipe history is cleared, and the game returns to the initial market check screen

### Requirement: Player can quit from the game over screen
The system SHALL provide a "Quit" button on the game over screen that exits the application.

#### Scenario: Quit exits the application
- **WHEN** the player presses "Quit" on the game over screen
- **THEN** the application closes
