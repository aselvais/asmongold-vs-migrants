extends Node2D

const VIEW_WIDTH := 1280.0
const VIEW_HEIGHT := 1024.0
const LEVEL_WIDTH := 6400.0
const START_LIVES := 3
const EXIT_X := 5400.0
const LEVEL_2_PATH := "res://scenes/level_2.tscn"
const BANNER_HOLD := 5.0
const BANNER_FADE := 0.8

@onready var camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $Player
@onready var music: AudioStreamPlayer = $Music
@onready var hud: Control = $HUD/Status
@onready var game_over: Control = $HUD/GameOver
@onready var try_again: Button = $HUD/GameOver/VBox/TryAgain
@onready var level_banner: Label = $HUD/LevelBanner
@onready var pause_menu: PauseMenu = $HUD/Pause
@onready var stairs: Marker2D = $SubwayStairs

var score := 0
var lives := START_LIVES
var _enemies_left := 0
var _exiting := false


func _ready() -> void:
	camera.make_current()
	if not music.finished.is_connected(music.play):
		music.finished.connect(music.play)
	if not music.playing:
		music.play()
	game_over.hide()
	if player.has_signal("died") and not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	if player.has_signal("health_changed") and not player.health_changed.is_connected(_on_player_health_changed):
		player.health_changed.connect(_on_player_health_changed)
	if not try_again.pressed.is_connected(_on_try_again):
		try_again.pressed.connect(_on_try_again)
	if pause_menu:
		pause_menu.can_pause = true
		pause_menu.hide()
	_connect_enemies()
	_refresh_hud()
	_show_level_banner()


func _physics_process(_delta: float) -> void:
	var half := VIEW_WIDTH * 0.5
	camera.global_position.x = clampf(player.global_position.x, half, LEVEL_WIDTH - half)
	camera.global_position.y = VIEW_HEIGHT * 0.5
	if _exiting or player.dead or bool(player.get("respawning")):
		return
	if _enemies_left <= 0 and player.global_position.x >= EXIT_X:
		_start_exit()


func _connect_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	_enemies_left = 0
	for enemy in enemies:
		if _enemy_counts_for_clear(enemy):
			_enemies_left += 1
		if enemy.has_signal("died") and not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died.bind(enemy))
		if enemy.has_signal("scored") and not enemy.scored.is_connected(_on_enemy_scored):
			enemy.scored.connect(_on_enemy_scored)


func _refresh_hud() -> void:
	if hud == null:
		return
	hud.set_health(player.current_health(), player.max_hits)
	hud.set_lives(lives, START_LIVES)
	hud.set_score(score)


func _show_level_banner() -> void:
	if level_banner == null:
		return
	level_banner.modulate.a = 1.0
	level_banner.show()
	await get_tree().create_timer(BANNER_HOLD).timeout
	if not is_instance_valid(level_banner):
		return
	var tween := create_tween()
	tween.tween_property(level_banner, "modulate:a", 0.0, BANNER_FADE)
	await tween.finished
	if is_instance_valid(level_banner):
		level_banner.hide()


func _on_player_health_changed(current: int, maximum: int) -> void:
	if hud:
		hud.set_health(current, maximum)


func _on_enemy_scored(points: int) -> void:
	score += points
	if hud:
		hud.set_score(score)


func _on_enemy_died(enemy: Node) -> void:
	if _enemy_counts_for_clear(enemy):
		_enemies_left = maxi(0, _enemies_left - 1)


func _enemy_counts_for_clear(enemy: Node) -> bool:
	if "can_attack" in enemy:
		return bool(enemy.can_attack)
	return true


func _on_player_died() -> void:
	if _exiting:
		return
	lives -= 1
	if hud:
		hud.set_lives(lives, START_LIVES)
	if lives <= 0:
		player.sprite.visible = true
		_disable_pause()
		game_over.show()
		try_again.grab_focus()
		get_tree().paused = true
		return
	if is_instance_valid(player):
		await player.revive()


func _on_try_again() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _disable_pause() -> void:
	if pause_menu == null:
		return
	pause_menu.can_pause = false
	pause_menu.hide()


func _start_exit() -> void:
	if _exiting:
		return
	_exiting = true
	_disable_pause()
	if music.finished.is_connected(music.play):
		music.finished.disconnect(music.play)
	music.stop()
	if is_instance_valid(player):
		await player.walk_into_stairs(stairs.global_position)
	get_tree().change_scene_to_file(LEVEL_2_PATH)
