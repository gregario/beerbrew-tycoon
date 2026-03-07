## ADDED Requirements

### Requirement: Automation equipment category support
The equipment system SHALL support "automation" as a valid equipment category alongside "brewing", "fermentation", "packaging", and "utility". Automation equipment SHALL have additional fields: mash_bonus (int), boil_bonus (int), ferment_bonus (int).

#### Scenario: Automation category recognized
- **WHEN** an equipment item has category "automation"
- **THEN** EquipmentManager SHALL treat it as valid equipment
- **THEN** it SHALL be placeable in station slots

### Requirement: Path-gated equipment purchasing
The EquipmentShop SHALL filter equipment based on the player's chosen path. Automation equipment SHALL only be shown to mass-market path players. This check SHALL use PathManager.get_current_path_name().

#### Scenario: Equipment shop filters by path
- **WHEN** a mass-market player browses the equipment shop
- **THEN** automation category items SHALL be visible
- **WHEN** an artisan player browses the equipment shop
- **THEN** automation category items SHALL be hidden

### Requirement: Automation bonus aggregation
EquipmentManager SHALL aggregate automation bonuses from all active (slotted) automation equipment. It SHALL expose methods: get_automation_mash_bonus(), get_automation_boil_bonus(), get_automation_ferment_bonus().

#### Scenario: Multiple automation items aggregate
- **WHEN** the player has Auto-Mash Controller (+5 mash) and Fermentation Controller (+7 ferment) in active slots
- **THEN** get_automation_mash_bonus() SHALL return 5
- **THEN** get_automation_ferment_bonus() SHALL return 7
- **THEN** get_automation_boil_bonus() SHALL return 0
