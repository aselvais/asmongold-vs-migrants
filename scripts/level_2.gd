extends Control

const MENU_PATH := "res://scenes/menu.tscn"

@onready var back_button: Button = $Center/VBox/Back


func _ready() -> void:
	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_PATH)
