extends Node
## Simple icon reference for game concepts.
## Replace Unicode with TextureRect when real pixel art icons are sourced.

const ICONS := {
	"beer": "🍺",
	"malt": "🌾",
	"hops": "🌿",
	"yeast": "🧫",
	"money": "$",
	"quality": "⭐",
	"turns": "#",
}

static func get_icon(key: String) -> String:
	return ICONS.get(key, "?")
