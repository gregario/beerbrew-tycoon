## ADDED Requirements

### Requirement: Staff data model
Each staff member SHALL be a Resource with: name (String), creativity (int 1-100), precision (int 1-100), experience_points (int), level (int 1-10), salary_per_turn (int), assigned_phase (String or null), and specialization (String: "none", "mashing", "boiling", "fermenting").

#### Scenario: Staff resource has all required properties
- **WHEN** a Staff resource is created
- **THEN** it SHALL have name, creativity, precision, experience_points, level, salary_per_turn, assigned_phase, and specialization

### Requirement: Hiring staff
The player SHALL be able to hire staff from a hiring screen. Available candidates are randomly generated each turn with varying stats and salary requirements. The garage stage allows 0 extra staff (solo). Microbrewery allows 1-2. Artisan/mass-market allows 3-4.

#### Scenario: Hiring a brewer in microbrewery stage
- **WHEN** the player is in the microbrewery stage with fewer than 2 staff
- **THEN** the hiring screen SHALL show 2-3 candidate brewers with stats and salary
- **WHEN** the player hires a candidate
- **THEN** the candidate SHALL be added to the staff roster
- **THEN** their salary SHALL be deducted from balance each turn

### Requirement: Staff assignment to brewing phases
Staff members SHALL be assignable to specific brewing phases (mashing, boiling, fermenting). An assigned staff member adds bonus points to that phase based on their stats: creativity adds to flavor points, precision adds to technique points.

#### Scenario: Staff assigned to mashing phase
- **WHEN** a staff member with creativity=60, precision=40 is assigned to mashing
- **THEN** the mashing phase SHALL receive bonus flavor points proportional to creativity (60)
- **THEN** the mashing phase SHALL receive bonus technique points proportional to precision (40)

### Requirement: Staff training and leveling
Staff gain experience after each brew they participate in. When experience reaches a threshold, they level up, increasing their stats. Between brews, the player can send staff to training (costs money) to boost a specific stat.

#### Scenario: Staff levels up after brewing
- **WHEN** a staff member gains enough experience to reach the next level
- **THEN** both creativity and precision SHALL increase by 2-5 points
- **THEN** the level-up SHALL be announced via toast notification

#### Scenario: Staff training boosts specific stat
- **WHEN** the player sends a staff member to "Creativity Training" ($200)
- **THEN** $200 SHALL be deducted from balance
- **THEN** the staff member's creativity SHALL increase by 5-10 points
- **THEN** the staff member SHALL be unavailable for one brew turn

### Requirement: Staff specialization
When a staff member reaches level 5, they can be specialized in one brewing phase. Specialization doubles their stat contribution when assigned to their specialized phase but halves it for other phases. This mirrors GDT's "better to maximize a skill than split evenly."

#### Scenario: Specialized staff assigned to their phase
- **WHEN** a staff member specialized in "mashing" is assigned to the mashing phase
- **THEN** their stat contributions SHALL be doubled compared to an unspecialized staff member
