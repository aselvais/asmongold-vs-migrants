extends Node2D

const VIEW_WIDTH := 1280.0
const VIEW_HEIGHT := 1024.0
const LEVEL_WIDTH := 6400.0

@onready var camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $Player
@onready var music: AudioStreamPlayer = $Music
@onready var game_over: Control = $HUD/GameOver
@onready var try_again: Button = $HUD/GameOver/VBox/TryAgain


func _ready() -> void:
	camera.make_current()
	if not music.finished.is_connected(music.play):
		music.finished.connect(music.play)
	if not music.playing:
		music.play()
	game_over.hide()
	if player.has_signal("died") and not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	if not try_again.pressed.is_connected(_on_try_again):
		try_again.pressed.connect(_on_try_again)


func _physics_process(_delta: float) -> void:
	var half := VIEW_WIDTH * 0.5
	camera.global_position.x = clampf(player.global_position.x, half, LEVEL_WIDTH - half)
	camera.global_position.y = VIEW_HEIGHT * 0.5


func _on_player_died() -> void:
	game_over.show()
	try_again.grab_focus()
	get_tree().paused = true


func _on_try_again() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
