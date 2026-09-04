extends Control

const LEVEL_1_PATH := "res://scenes/level_1.tscn"

@onready var play_button: Button = $Center/VBox/Play
@onready var music: AudioStreamPlayer = $Music


func _ready() -> void:
	if not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)
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
	get_tree().change_scene_to_file(LEVEL_1_PATH)
