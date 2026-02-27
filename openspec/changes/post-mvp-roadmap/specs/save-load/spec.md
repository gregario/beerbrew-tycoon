## ADDED Requirements

### Requirement: Save game state to file
The game SHALL save the complete run state to a JSON file at `user://saves/run_save.json`. Saved state SHALL include: GameState (balance, turn, brew history, market state), equipment owned, staff hired, research completed, and all runtime resource instances.

#### Scenario: Game state is saved
- **WHEN** the player triggers save (via menu or auto-save)
- **THEN** a JSON file SHALL be written to user://saves/run_save.json
- **THEN** the file SHALL contain all state needed to restore the exact game position

### Requirement: Load game state from file
The game SHALL load a saved run state from `user://saves/run_save.json` and restore all game systems to their saved state. After loading, the player SHALL continue from exactly where they left off.

#### Scenario: Game state is loaded
- **WHEN** the player selects "Continue" from the main menu
- **THEN** the game SHALL read user://saves/run_save.json
- **THEN** all game state SHALL be restored (balance, turn, history, equipment, staff, research)
- **THEN** the player SHALL see the brewery in its saved state

### Requirement: Auto-save after each brew
The game SHALL automatically save after each completed brew turn. This ensures no progress is lost if the game is closed unexpectedly.

#### Scenario: Auto-save triggers after brew
- **WHEN** a brew turn completes (results screen shown)
- **THEN** the game SHALL automatically save state to user://saves/run_save.json

### Requirement: Meta-progression saves separately
Cross-run meta-progression data SHALL be saved to a separate file `user://saves/meta.json`. This file SHALL persist independently of run saves and SHALL NOT be deleted when a run ends.

#### Scenario: Meta-progression persists across runs
- **WHEN** a run ends (win or loss)
- **THEN** meta-progression unlocks SHALL be saved to user://saves/meta.json
- **THEN** the run save file SHALL be deleted
- **THEN** meta.json SHALL remain for the next run

### Requirement: Save format versioning
Each save file SHALL include a `version` field (integer). When loading a save with a lower version than current, a migration function SHALL update the save data to the current format.

#### Scenario: Old save format is migrated
- **WHEN** a save file with version 1 is loaded by a game expecting version 2
- **THEN** the migration function SHALL transform the data to version 2 format
- **THEN** the game SHALL load successfully with migrated data
