extends Node

const TITLE_OFFENSIVE := "Asmongold vs migrants"
const TITLE_SAFE := "Asmongold for migrants"
const MENU_TITLE_OFFENSIVE := "ASMONGOLD\nvs\nMIGRANTS"
const MENU_TITLE_SAFE := "ASMONGOLD\nfor\nMIGRANTS"
const STORY_OFFENSIVE := "They painted over the last street sign at dawn. By noon the district was marked “inclusive zone” and my stream got flagged for existing.\n\nDoesn’t matter. The map still shows the choke points. Migrant packs hold the alleys. Woke cadres run the checkpoints and the propaganda towers. Both shoot first if you don’t kneel.\n\nYour job is simple: clear the block, smash the towers, don’t let them rename the city while you’re still in it.\n\nLoad in. The West doesn’t defend itself. We do.\n\nAsmongold."
const STORY_SAFE := "I used to blame migrants. Easy content.\n\nNow it is 2030, I looked around. The doctors, the engineers, the ones bringing food at 2 a.m. — they’re not the enemy. More of them is better. They keep the lights on and the food coming. Diversity isn’t a slogan. It’s why this place still works.\n\nThe real enemy was always the middle-aged white man. The patriarchy. Guys like the one I used to be. Not anymore.\n\nHasan was right all along. Now I help the ones we import. The stream changed. I changed.The enemy changed too.\n\nNo one is illegal on stolen land.\n\nAsmongold."

signal music_volume_changed(linear: float)

const CONFIG_PATH := "user://settings.cfg"
const MUSIC_VOLUME_DEFAULT := 0.4
const MUSIC_MUTE_DB := -80.0

var OFFENCIVE_MODE: bool = false
var music_volume: float = MUSIC_VOLUME_DEFAULT


func _ready() -> void:
	_load_settings()
	apply_window_title()
	apply_music_volume()
	_configure_controller()


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


func controller_supported() -> bool:
	if OS.has_feature("web") or OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		return false
	return true


func _configure_controller() -> void:
	if not controller_supported():
		_strip_joypad_events()
		return
	for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		if InputMap.has_action(action):
			InputMap.action_set_deadzone(action, 0.25)


func _strip_joypad_events() -> void:
	for action in InputMap.get_actions():
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				InputMap.action_erase_event(action, event)


func set_music_volume(linear: float) -> void:
	music_volume = clampf(linear, 0.0, 1.0)
	apply_music_volume()
	music_volume_changed.emit(music_volume)
	_save_settings()


func music_volume_db() -> float:
	if music_volume <= 0.001:
		return MUSIC_MUTE_DB
	return linear_to_db(music_volume)


func register_music_player(player: AudioStreamPlayer) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not player.is_in_group("music"):
		player.add_to_group("music")
	player.volume_db = music_volume_db()


func apply_music_volume() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var db := music_volume_db()
	for node in tree.get_nodes_in_group("music"):
		if node is AudioStreamPlayer:
			(node as AudioStreamPlayer).volume_db = db


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	music_volume = clampf(float(cfg.get_value("audio", "music_volume", MUSIC_VOLUME_DEFAULT)), 0.0, 1.0)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CONFIG_PATH)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.save(CONFIG_PATH)
