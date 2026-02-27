## ADDED Requirements

### Requirement: Results screen is shown after every brew
The system SHALL display a results screen as an overlay after every brew completes. The screen SHALL appear before the player can start the next turn.

#### Scenario: Results screen appears post-brew
- **WHEN** the player presses the "Brew" button and quality is calculated
- **THEN** the results overlay is displayed before returning to the market check screen

### Requirement: Results screen displays the brewed beer's identity
The system SHALL display the beer style name and the ingredient combination (malt, hop, yeast) used in the just-completed brew.

#### Scenario: Beer identity visible
- **WHEN** the results screen is shown
- **THEN** the style name and all three selected ingredients are clearly labeled

### Requirement: Quality score and breakdown are displayed
The system SHALL display the final quality score (0–100) prominently and a breakdown showing the contribution of each scoring component (ratio match, ingredient compatibility, novelty, base effort).

#### Scenario: Score and breakdown visible
- **WHEN** the results screen is shown
- **THEN** the numeric quality score and a labeled breakdown of component contributions are both visible

### Requirement: Revenue and updated balance are displayed
The system SHALL display the revenue earned from selling the brew and the player's updated cash balance after the sale.

#### Scenario: Revenue and balance visible
- **WHEN** the results screen is shown
- **THEN** the revenue earned and the new balance are clearly displayed

### Requirement: Results screen has a continue action
The system SHALL provide a "Continue" button (or equivalent) on the results screen that advances the game to the next turn (market check screen).

#### Scenario: Continue advances the turn
- **WHEN** the player presses "Continue" on the results screen
- **THEN** the game transitions to the market check screen for the next turn

### Requirement: Rent notification is shown when rent is due
The system SHALL display a rent deduction notice on the results screen of the turn when rent is collected, showing the rent amount and the post-rent balance.

#### Scenario: Rent notice on due turn
- **WHEN** the current turn is a rent turn and the results screen is shown
- **THEN** the rent amount and updated balance after rent are visible in the results display
