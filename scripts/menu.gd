extends Control

const LEVEL_1_PATH := "res://scenes/level_1.tscn"
const CHECK_COLOR := Color(1, 0.85, 0.2, 1)
const TERMS_TEXT := """OFFENSIVE MODE — TERMS AND CONDITIONS (PLACEHOLDER)

Replace this text later. The copy below is dummy content so the window can be scrolled from top to bottom.

1. Acknowledgement
By enabling Offensive Mode, you confirm that you are of legal age in your jurisdiction and that you choose to see unfiltered in-game speech, slogans, and related audio that some players will find offensive, political, or otherwise objectionable.

2. Nature of the content
Offensive Mode restores enemy speech bubbles and the original strike voice lines. The rest of the game, including combat, scoring, and level flow, is unchanged. Disabling Offensive Mode hides those lines and replaces the associated shout with a generic punch sound.

3. Voluntary opt-in
Offensive Mode is off by default. You are not required to enable it to play. Checking the box and pressing I ACCEPT is the only way this mode turns on for the current session.

4. No endorsement
Placeholder studio, publishers, platforms, and performers do not endorse the views expressed by in-game characters. Character dialogue is satirical, exaggerated, and presented as fiction.

5. Your responsibility
You agree not to use recordings, screenshots, or quotes from Offensive Mode to harass real people. You also agree that you will not hold the authors liable for discomfort, offense, or reputational harm arising from content you chose to enable.

6. Session scope
Acceptance applies to this play session. If you uncheck Offensive Mode, the extra speech and audio are suppressed again. Checking the box later will show these terms again.

7. Placeholder legal section
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer vitae nisi ut lorem tincidunt tincidunt. Suspendisse potenti. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae.

8. Another placeholder section
Curabitur blandit tempus porttitor. Integer posuere erat a ante venenatis dapibus posuere velit aliquet. Donec sed odio dui. Morbi leo risus, porta ac consectetur ac, vestibulum at eros. Aenean lacinia bibendum nulla sed consectetur. Praesent commodo cursus magna, vel scelerisque nisl consectetur et.

9. Accessibility and scrolling
You should be able to scroll this entire notice with the mouse wheel, the scrollbar, or the arrow keys until the last paragraph is visible. If you cannot read a later section, keep scrolling. The I ACCEPT button stays at the bottom of the window and does not scroll away.

10. Final placeholder paragraph
This last block exists so the terms are long enough to require scrolling on a 1024-pixel-tall layout. Replace paragraphs 1 through 10 with the real terms when they are ready. Until then, pressing I ACCEPT only means you have seen this placeholder and want Offensive Mode enabled.

End of placeholder terms."""

@onready var play_button: Button = $Center/VBox/Actions/Play
@onready var offensive_mode: CheckBox = $Center/VBox/Actions/OffensiveMode
@onready var music: AudioStreamPlayer = $Music
@onready var terms_dialog: Control = $TermsDialog
@onready var terms_dim: ColorRect = $TermsDialog/Dim
@onready var terms_panel: PanelContainer = $TermsDialog/Center/Panel
@onready var terms_scroll: ScrollContainer = $TermsDialog/Center/Panel/Margin/VBox/Scroll
@onready var terms_body: Label = $TermsDialog/Center/Panel/Margin/VBox/Scroll/Body
@onready var accept_button: Button = $TermsDialog/Center/Panel/Margin/VBox/Accept


func _ready() -> void:
	_style_offensive_checkbox()
	_style_terms_dialog()
	offensive_mode.set_pressed_no_signal(GameSettings.OFFENCIVE_MODE)
	if not offensive_mode.toggled.is_connected(_on_offensive_mode_toggled):
		offensive_mode.toggled.connect(_on_offensive_mode_toggled)
	if not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)
	if not accept_button.pressed.is_connected(_on_terms_accepted):
		accept_button.pressed.connect(_on_terms_accepted)
	if not terms_dim.gui_input.is_connected(_on_terms_dim_gui_input):
		terms_dim.gui_input.connect(_on_terms_dim_gui_input)
	if not terms_scroll.resized.is_connected(_sync_terms_body_width):
		terms_scroll.resized.connect(_sync_terms_body_width)
	terms_dialog.hide()
	play_button.grab_focus()
	_start_music()


func _start_music() -> void:
	if music.stream != null and "loop" in music.stream:
		music.stream.loop = true
	if not music.finished.is_connected(music.play):
		music.finished.connect(music.play)
	if not music.playing:
		music.play()


func _on_play_pressed() -> void:
	if terms_dialog.visible:
		return
	GameSettings.OFFENCIVE_MODE = offensive_mode.button_pressed
	get_tree().change_scene_to_file(LEVEL_1_PATH)


func _on_offensive_mode_toggled(pressed: bool) -> void:
	if pressed:
		offensive_mode.set_pressed_no_signal(false)
		_show_terms()
		return
	GameSettings.OFFENCIVE_MODE = false


func _unhandled_input(event: InputEvent) -> void:
	if not terms_dialog.visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		_hide_terms()
		get_viewport().set_input_as_handled()


func _on_terms_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_terms()


func _show_terms() -> void:
	terms_body.text = TERMS_TEXT
	terms_dialog.show()
	terms_scroll.scroll_vertical = 0
	accept_button.grab_focus()
	call_deferred("_sync_terms_body_width")


func _hide_terms() -> void:
	terms_dialog.hide()
	offensive_mode.grab_focus()


func _on_terms_accepted() -> void:
	offensive_mode.set_pressed_no_signal(true)
	GameSettings.OFFENCIVE_MODE = true
	_hide_terms()


func _sync_terms_body_width() -> void:
	var width := terms_scroll.size.x
	var bar := terms_scroll.get_v_scroll_bar()
	if bar:
		width -= bar.size.x
	terms_body.custom_minimum_size.x = maxf(0.0, width - 8.0)


func _style_terms_dialog() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.1, 0.98)
	panel_style.border_color = CHECK_COLOR
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(4)
	terms_panel.add_theme_stylebox_override("panel", panel_style)
	terms_body.add_theme_font_size_override("font_size", 12)
	terms_body.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	terms_body.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	terms_body.add_theme_constant_override("outline_size", 4)
	terms_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _style_offensive_checkbox() -> void:
	var empty := StyleBoxEmpty.new()
	for style_name in ["normal", "pressed", "hover", "hover_pressed", "focus", "disabled"]:
		offensive_mode.add_theme_stylebox_override(style_name, empty)
	offensive_mode.add_theme_color_override("font_color", CHECK_COLOR)
	offensive_mode.add_theme_color_override("font_pressed_color", CHECK_COLOR)
	offensive_mode.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.7, 1))
	offensive_mode.add_theme_color_override("font_hover_pressed_color", Color(1, 0.95, 0.7, 1))
	offensive_mode.add_theme_color_override("font_focus_color", CHECK_COLOR)
	offensive_mode.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	offensive_mode.add_theme_constant_override("outline_size", 4)
	offensive_mode.add_theme_constant_override("h_separation", 12)
	offensive_mode.add_theme_font_size_override("font_size", 14)
	var unchecked := _make_check_icon(false)
	var checked := _make_check_icon(true)
	offensive_mode.add_theme_icon_override("unchecked", unchecked)
	offensive_mode.add_theme_icon_override("unchecked_disabled", unchecked)
	offensive_mode.add_theme_icon_override("checked", checked)
	offensive_mode.add_theme_icon_override("checked_disabled", checked)


func _make_check_icon(checked: bool) -> Texture2D:
	const SIZE := 22
	const BORDER := 3
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.06, 0.06, 0.08, 1))
	for x in SIZE:
		for y in SIZE:
			if x < BORDER or y < BORDER or x >= SIZE - BORDER or y >= SIZE - BORDER:
				img.set_pixel(x, y, CHECK_COLOR)
	if checked:
		for i in range(5, 10):
			img.set_pixel(i, 11 + (i - 5), CHECK_COLOR)
			img.set_pixel(i, 12 + (i - 5), CHECK_COLOR)
			img.set_pixel(i, 13 + (i - 5), CHECK_COLOR)
		for i in range(10, 17):
			img.set_pixel(i, 21 - i, CHECK_COLOR)
			img.set_pixel(i, 22 - i, CHECK_COLOR)
			img.set_pixel(i, 23 - i, CHECK_COLOR)
	return ImageTexture.create_from_image(img)
