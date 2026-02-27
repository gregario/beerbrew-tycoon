## ADDED Requirements

### Requirement: Player has a cash balance that changes each turn
The system SHALL maintain a cash balance for the player. The balance starts at a defined starting amount (default: $500). Each brew deducts ingredient costs and adds revenue from selling the brewed beer. If the balance reaches $0 or the player cannot afford the next brew, a loss condition is triggered.

#### Scenario: Balance increases after a successful sell
- **WHEN** a brew completes and the beer is sold
- **THEN** the player's balance increases by the revenue amount for that brew

#### Scenario: Balance decreases by ingredient cost before brewing
- **WHEN** the player confirms a recipe and starts a brew
- **THEN** the ingredient cost is deducted from the balance before the brewing phases begin

### Requirement: Revenue is derived from quality score, demand multiplier, and base price
The system SHALL calculate revenue as: `base_price × quality_multiplier × demand_multiplier`. Base price is a style-defined constant. Quality multiplier maps quality score to a 0.5–2.0× multiplier (score 50 = 1.0×, score 100 = 2.0×, score 0 = 0.5×). Demand multiplier comes from the market system.

#### Scenario: High quality brew earns more revenue
- **WHEN** two brews of the same style are sold with quality scores of 80 and 40 respectively
- **THEN** the 80-quality brew SHALL generate substantially more revenue than the 40-quality brew

#### Scenario: Revenue formula is consistent
- **WHEN** a brew sells with quality score 50, demand 1.0×, and base price $200
- **THEN** revenue is exactly $200 (1.0 quality multiplier × 1.0 demand × $200)

### Requirement: Rent is charged every N turns
The system SHALL deduct a rent amount from the player's balance every N turns (default: every 4 turns, rent = $150). Rent is deducted automatically at the end of the Nth turn's results screen.

#### Scenario: Rent deducted on schedule
- **WHEN** the Nth turn completes (default: every 4th turn)
- **THEN** the rent amount is deducted from the balance and the player is notified

#### Scenario: Insufficient funds at rent triggers loss
- **WHEN** rent is due but the player's balance is less than the rent amount
- **THEN** the loss condition is triggered immediately

### Requirement: Win condition is a cash milestone
The system SHALL trigger a win condition when the player's cash balance reaches or exceeds the win target (default: $10,000). The win is checked after each revenue calculation.

#### Scenario: Reaching the milestone triggers win
- **WHEN** a brew's revenue brings the balance to $10,000 or above
- **THEN** the win condition is triggered and the game-over screen shows a win state

### Requirement: Loss condition triggers when the player cannot continue
The system SHALL trigger a loss condition when either: (a) the player's balance drops to $0 or below after rent, or (b) the player cannot afford the minimum ingredient cost to start the next brew.

#### Scenario: Bankruptcy triggers loss
- **WHEN** the player's balance after all deductions is $0 or below
- **THEN** the loss condition is triggered

#### Scenario: Cannot afford next brew triggers loss
- **WHEN** rent has been paid and the player's remaining balance is less than the cheapest possible ingredient cost
- **THEN** the loss condition is triggered

### Requirement: All financial constants are configurable
The system SHALL store starting balance, win target, rent amount, rent interval (turns), and base ingredient costs as named constants in a configuration location accessible to tests and gameplay code alike.

#### Scenario: Constants used consistently
- **WHEN** the game initializes
- **THEN** all economy values are sourced from the named constants, not hardcoded inline

### Requirement: execute_brew is the canonical entry point for a brew turn
The system SHALL use `GameState.execute_brew(sliders)` as the single, authoritative entry point for executing a brew turn. No external caller (UI scene, test, or other system) SHALL directly sequence the individual economy methods (deduct_ingredient_cost, calculate_revenue, add_revenue, record_brew, advance_state) to perform a brew turn. Those methods remain public for isolated unit testing only.

#### Scenario: Single entry point enforced by convention
- **WHEN** a brew turn is triggered from any UI scene
- **THEN** the scene emits a signal, and the signal handler calls `GameState.execute_brew()` — not the individual methods in sequence
