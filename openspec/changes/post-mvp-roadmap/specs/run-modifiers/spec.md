## ADDED Requirements

### Requirement: Run modifier selection
Before starting a new run, the player SHALL be able to select 0-2 run modifiers that change game parameters. Modifiers are unlocked through meta-progression achievements.

#### Scenario: Player selects run modifiers
- **WHEN** the player starts a new run
- **THEN** available run modifiers SHALL be displayed
- **WHEN** the player selects up to 2 modifiers
- **THEN** those modifiers SHALL affect game parameters for the entire run
- **THEN** selected modifiers SHALL be visible on the brewery info screen

### Requirement: Modifier types
Run modifiers SHALL include challenge modifiers and bonus modifiers. Challenge modifiers increase difficulty but award more unlock points: "Tough Market" (demand multipliers reduced 20%), "Budget Brewery" (starting cash halved), "Ingredient Shortage" (only 60% of ingredients available). Bonus modifiers ease the run: "Master Brewer" (+10% quality), "Lucky Break" (first 5 brews have no infection risk), "Generous Market" (base demand +20%).

#### Scenario: Challenge modifier increases reward
- **WHEN** the player completes a run with "Tough Market" active
- **THEN** unlock points earned SHALL be multiplied by 1.5

#### Scenario: Bonus modifier applies effect
- **WHEN** the player starts a run with "Master Brewer" active
- **THEN** all quality scores SHALL receive a +10% bonus for the entire run

### Requirement: Achievement-based modifier unlocks
Each modifier SHALL be unlocked by a specific achievement: "Tough Market" unlocked by winning a run, "Budget Brewery" unlocked by winning with less than $1000 spent on equipment, "Master Brewer" unlocked by brewing a 95+ quality beer.

#### Scenario: Achievement unlocks modifier
- **WHEN** the player wins a run for the first time
- **THEN** "Tough Market" modifier SHALL be permanently unlocked for future runs
