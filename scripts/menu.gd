extends Control

const LEVEL_1_PATH := "res://scenes/level_1.tscn"

@onready var play_button: Button = $Center/VBox/Play


func _ready() -> void:
	if not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)
	play_button.grab_focus()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(LEVEL_1_PATH)
