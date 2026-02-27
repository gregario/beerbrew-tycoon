## ADDED Requirements

### Requirement: Competition events
Beer competitions SHALL occur every 8-10 turns. The player can enter one beer per competition. Competitions have a style category (or "open" for any style), an entry fee, and prize tiers (gold, silver, bronze).

#### Scenario: Competition announced
- **WHEN** a competition event triggers
- **THEN** a notification SHALL announce the competition with category, entry fee, and prize amounts
- **THEN** the player SHALL have 2 turns to brew and submit an entry

### Requirement: Competition judging
Submitted beers SHALL be judged against 3 simulated competitors. Competitor scores SHALL be randomly generated within a range that scales with game progression (higher scores in later turns). The player's beer quality score determines their ranking.

#### Scenario: Player wins gold
- **WHEN** the player's submitted beer scores higher than all 3 competitors
- **THEN** the player SHALL receive the gold prize (cash + reputation bonus)
- **THEN** a "Gold Medal" achievement tag SHALL be added to that beer's history

#### Scenario: Player doesn't place
- **WHEN** the player's submitted beer scores lower than all 3 competitors
- **THEN** the player SHALL receive no prize
- **THEN** the entry fee SHALL NOT be refunded

### Requirement: Competition prizes affect progression
Competition wins SHALL award cash prizes, reputation points, and occasional unique unlocks (rare ingredients, equipment discounts). Gold medals contribute to the artisan path's win condition.

#### Scenario: Gold medal unlocks rare ingredient
- **WHEN** the player wins gold in a competition
- **THEN** a rare ingredient MAY be unlocked (25% chance per gold)
- **THEN** reputation SHALL increase significantly
