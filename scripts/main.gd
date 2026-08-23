extends Node2D

const VIEW_WIDTH := 1280.0
const VIEW_HEIGHT := 1024.0
const LEVEL_WIDTH := 6400.0

@onready var camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $Player
@onready var music: AudioStreamPlayer = $Music


func _ready() -> void:
	camera.make_current()
	if not music.finished.is_connected(music.play):
		music.finished.connect(music.play)
	if not music.playing:
		music.play()


func _physics_process(_delta: float) -> void:
	var half := VIEW_WIDTH * 0.5
	camera.global_position.x = clampf(player.global_position.x, half, LEVEL_WIDTH - half)
	camera.global_position.y = VIEW_HEIGHT * 0.5
