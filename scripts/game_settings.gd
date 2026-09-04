extends Node

const TITLE_OFFENSIVE := "Asmongold vs migrants"
const TITLE_SAFE := "Asmongold for migrants"
const MENU_TITLE_OFFENSIVE := "ASMONGOLD\nvs\nMIGRANTS"
const MENU_TITLE_SAFE := "ASMONGOLD\nfor\nMIGRANTS"
const STORY_OFFENSIVE := "They painted over the last street sign at dawn. By noon the district was marked “inclusive zone” and my stream got flagged for existing.\n\nDoesn’t matter. The map still shows the choke points. Migrant packs hold the alleys. Woke cadres run the checkpoints and the propaganda towers. Both shoot first if you don’t kneel.\n\nYour job is simple: clear the block, smash the towers, don’t let them rename the city while you’re still in it.\n\nLoad in. The West doesn’t defend itself. We do.\n\nAsmongold."
const STORY_SAFE := "I used to blame migrants. Easy content.\n\nNow it is 2030, I looked around. The doctors, the engineers, the ones bringing food at 2 a.m. — they’re not the enemy. More of them is better. They keep the lights on and the food coming. Diversity isn’t a slogan. It’s why this place still works.\n\nThe real enemy was always the middle-aged white man. The patriarchy. Guys like the one I used to be. Not anymore.\n\nHasan was right all along. Now I help the ones we import. The stream changed. I changed.The enemy changed too.\n\nNo one is illegal on stolen land.\n\nAsmongold."

var OFFENCIVE_MODE: bool = false


func _ready() -> void:
	apply_window_title()


func roles_flipped() -> bool:
	return not OFFENCIVE_MODE


func display_title() -> String:
	return TITLE_OFFENSIVE if OFFENCIVE_MODE else TITLE_SAFE


func menu_title() -> String:
	return MENU_TITLE_OFFENSIVE if OFFENCIVE_MODE else MENU_TITLE_SAFE


func story_text() -> String:
	return STORY_OFFENSIVE if OFFENCIVE_MODE else STORY_SAFE


func apply_window_title() -> void:
	DisplayServer.window_set_title(display_title())
