## ADDED Requirements

### Requirement: Automation equipment category
The equipment system SHALL support a new "automation" category. Automation equipment SHALL provide flat bonuses to brewing phases (mash, boil, ferment) independent of staff assignment.

#### Scenario: Automation equipment has correct category
- **WHEN** an automation equipment resource is loaded
- **THEN** its category SHALL be "automation"
- **THEN** it SHALL have phase-specific bonus fields (mash_bonus, boil_bonus, ferment_bonus)

### Requirement: Automation equipment is mass-market exclusive
Automation equipment SHALL only be available for purchase by players on the mass-market path. The EquipmentShop SHALL hide or disable automation items for artisan path players.

#### Scenario: Mass-market player sees automation equipment
- **WHEN** a mass-market path player opens the EquipmentShop
- **THEN** automation equipment SHALL be visible and purchasable (if affordable)

#### Scenario: Artisan player cannot access automation
- **WHEN** an artisan path player opens the EquipmentShop
- **THEN** automation equipment SHALL NOT be displayed

### Requirement: Automation bonus does not stack with staff bonus
For each brewing phase, the system SHALL apply the HIGHER of the automation bonus or the staff bonus, not both. This prevents double-dipping while letting players choose their strategy.

#### Scenario: Automation higher than staff
- **WHEN** automation provides +8 mash bonus and staff provides +5 mash bonus
- **THEN** the effective mash bonus SHALL be +8 (automation wins)

#### Scenario: Staff higher than automation
- **WHEN** automation provides +5 ferment bonus and staff provides +10 ferment bonus
- **THEN** the effective ferment bonus SHALL be +10 (staff wins)

#### Scenario: Phase-by-phase comparison
- **WHEN** automation provides +8 mash / +3 boil and staff provides +5 mash / +7 boil
- **THEN** effective bonuses SHALL be +8 mash (automation) and +7 boil (staff)

### Requirement: Automation equipment catalog
The game SHALL include at least 4 automation equipment items across tiers 3-5: Auto-Mash Controller (T3), Automated Boil System (T4), Fermentation Controller (T4), and Full Automation Suite (T5).

#### Scenario: Automation equipment tiers
- **WHEN** the automation catalog is loaded
- **THEN** it SHALL contain items at tiers 3, 4, and 5
- **THEN** each item SHALL have increasing phase bonuses at higher tiers

### Requirement: Automation equipment uses station slots
Automation equipment SHALL occupy station slots like regular equipment. Players must manage slot allocation between brewing equipment and automation.

#### Scenario: Automation occupies a slot
- **WHEN** the player installs an Auto-Mash Controller
- **THEN** it SHALL occupy one station slot
- **THEN** the remaining available slots SHALL decrease by one

### Requirement: Automation bonuses display in brewing phases
During brewing, the UI SHALL show automation bonuses alongside staff bonuses, with the active (higher) bonus highlighted. This helps players understand which source is contributing.

#### Scenario: Brewing phase shows automation vs staff
- **WHEN** the player is in the mashing phase with both automation and staff bonuses
- **THEN** both bonus values SHALL be displayed
- **THEN** the higher bonus SHALL be visually highlighted as "active"
