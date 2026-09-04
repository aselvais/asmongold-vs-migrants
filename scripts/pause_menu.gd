class_name PauseMenu
extends Control

const MENU_PATH := "res://scenes/menu.tscn"

var can_pause := true

@onready var resume_button: Button = $VBox/Resume
@onready var menu_button: Button = $VBox/BackToMenu


func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not resume_button.pressed.is_connected(_on_resume_pressed):
		resume_button.pressed.connect(_on_resume_pressed)
	if not menu_button.pressed.is_connected(_on_menu_pressed):
		menu_button.pressed.connect(_on_menu_pressed)


func _input(event: InputEvent) -> void:
	if not _is_pause_pressed(event):
		return
	if not can_pause:
		return
	get_viewport().set_input_as_handled()
	if visible:
		_on_resume_pressed()
	else:
		pause_game()


func pause_game() -> void:
	if not can_pause or visible:
		return
	show()
	get_tree().paused = true
	resume_button.grab_focus()


func _on_resume_pressed() -> void:
	hide()
	get_tree().paused = false


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_PATH)


func _is_pause_pressed(event: InputEvent) -> bool:
	if event.is_action_pressed(&"ui_cancel"):
		return true
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE
