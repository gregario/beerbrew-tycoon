## ADDED Requirements

### Requirement: Contract data model
Each contract SHALL have: client_name (String), required_style (String), minimum_quality (float), reward (int), bonus_reward (int for exceeding quality), deadline_turns (int), and reputation_penalty (int for failure).

#### Scenario: Contract resource has all required properties
- **WHEN** a Contract is generated
- **THEN** it SHALL have client_name, required_style, minimum_quality, reward, bonus_reward, deadline_turns, and reputation_penalty

### Requirement: Contract board with available contracts
The game SHALL offer 2-3 contracts per turn cycle (refreshing every 3 turns). Contracts are displayed on a contracts board screen. The player can accept up to 2 active contracts simultaneously.

#### Scenario: Contract board shows available contracts
- **WHEN** the player opens the contracts screen
- **THEN** 2-3 available contracts SHALL be displayed with requirements and rewards
- **THEN** accepted contracts SHALL be shown separately with remaining deadline

### Requirement: Fulfilling contracts
A contract is fulfilled when the player brews a beer matching the required style with quality at or above minimum_quality before the deadline expires. Fulfillment awards the reward (+ bonus_reward if quality exceeds minimum by 20+). Failed contracts (missed deadline or insufficient quality) deduct the reputation_penalty.

#### Scenario: Contract fulfilled with bonus
- **WHEN** the player brews a Stout with quality 85 for a contract requiring Stout at minimum quality 60
- **THEN** the contract SHALL be marked fulfilled
- **THEN** the player SHALL receive reward + bonus_reward (quality exceeded by 25)

#### Scenario: Contract deadline expires
- **WHEN** a contract's deadline_turns reaches 0 without fulfillment
- **THEN** the contract SHALL be marked failed
- **THEN** reputation_penalty SHALL be applied
