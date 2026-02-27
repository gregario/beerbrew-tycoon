## MODIFIED Requirements

### Requirement: Phase slider allocation
Each brewing phase (Mashing, Boiling, Fermenting) SHALL have an effort allocation slider. Post-MVP, each slider SHALL also display a contextual parameter: Mashing slider shows mapped mash temperature (62-69°C). Boiling slider shows hop schedule emphasis (Bittering ↔ Aroma). Fermenting slider shows fermentation temperature relative to yeast ideal range. Sliders default to 50%. Each phase has a distinct Flavor/Technique contribution profile that now interacts with ingredient properties and equipment stats.

#### Scenario: Mashing slider shows temperature
- **WHEN** the player adjusts the mashing slider
- **THEN** the displayed mash temperature SHALL update (62°C at 0%, 69°C at 100%)
- **THEN** a tooltip SHALL explain the fermentability trade-off

#### Scenario: Fermenting slider shows temp relative to yeast
- **WHEN** the player has selected a yeast with ideal range 18-22°C
- **THEN** the fermenting slider SHALL show the mapped temperature
- **THEN** a green zone indicator SHALL mark the yeast's ideal range on the slider

## ADDED Requirements

### Requirement: Staff assignment slots per phase
Each brewing phase SHALL have a staff assignment slot (empty in garage stage, usable from microbrewery). Assigned staff contribute bonus flavor/technique points based on their creativity/precision stats.

#### Scenario: Staff assigned to phase contributes bonus points
- **WHEN** a staff member with creativity=60 is assigned to the mashing phase
- **THEN** the mashing phase SHALL generate additional flavor points proportional to creativity
- **THEN** the staff assignment SHALL be visible on the brewing phases screen

### Requirement: Unlocked technique modifiers per phase
Researched techniques SHALL appear as toggleable options on relevant phases. Each technique modifier adjusts the phase's point generation. Examples: "Step Mash" on mashing (more technique points, less flavor variance), "Dry Hopping" on fermenting (more flavor points, costs extra hops).

#### Scenario: Dry hopping toggle on fermenting phase
- **WHEN** the player has researched "Dry Hopping"
- **THEN** a "Dry Hop" toggle SHALL appear on the fermenting phase
- **WHEN** enabled
- **THEN** flavor points from fermenting SHALL increase by 20%
- **THEN** an additional hop cost SHALL be deducted
