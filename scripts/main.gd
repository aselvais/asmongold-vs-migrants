extends Node2D

const VIEW_WIDTH := 1280.0
const VIEW_HEIGHT := 1024.0
const LEVEL_WIDTH := 6400.0
const START_LIVES := 3
const EXIT_X := 5400.0
const BANNER_FADE := 0.8
const COUNTDOWN_BEAT := 0.35
const COUNTDOWN_STEP := 1.0
const GO_HOLD := 0.85

@export_file("*.tscn") var next_level_path := "res://scenes/level_2.tscn"
@export var stage_top: float = 1024.0 * 2.0 / 3.0
@export var stage_bottom: float = 890.0
@export var randomize_enemy_positions := false
@export var enemy_min_x := 980.0
@export var enemy_max_x := 5200.0

@onready var camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $Player
@onready var music: AudioStreamPlayer = $Music
@onready var hud: Control = $HUD/Status
@onready var game_over: Control = $HUD/GameOver
@onready var try_again: Button = $HUD/GameOver/VBox/TryAgain
@onready var level_banner: Control = $HUD/LevelBanner
@onready var countdown_label: Label = $HUD/LevelBanner/Countdown
@onready var pause_menu: PauseMenu = $HUD/Pause
@onready var stairs: Marker2D = $SubwayStairs

var score := 0
var lives := START_LIVES
var _enemies_left := 0
var _exiting := false


func _ready() -> void:
	GameSettings.apply_window_title()
	camera.make_current()
	GameSettings.register_music_player(music)
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
	_randomize_enemy_positions()
	_apply_stage_bounds()
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


func _randomize_enemy_positions() -> void:
	if not randomize_enemy_positions:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	enemies.shuffle()
	var n := enemies.size()
	var span := maxf(1.0, enemy_max_x - enemy_min_x)
	for i in n:
		var slot := (float(i) + randf_range(0.12, 0.88)) / float(n)
		var x := clampf(enemy_min_x + slot * span, enemy_min_x, enemy_max_x)
		var y := randf_range(stage_top + 6.0, stage_bottom - 6.0)
		var body := enemies[i] as Node2D
		if body == null:
			continue
		body.global_position = Vector2(x, y)
		if "_home" in body:
			body._home = body.global_position


func _apply_stage_bounds() -> void:
	_set_actor_stage_bounds(player)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		_set_actor_stage_bounds(enemy)


func _set_actor_stage_bounds(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if "STAGE_TOP" in actor:
		actor.STAGE_TOP = stage_top
	if "STAGE_BOTTOM" in actor:
		actor.STAGE_BOTTOM = stage_bottom
	if actor is Node2D:
		var body := actor as Node2D
		var held: bool = actor.get("intro_held") == true or actor.get("dropping_in") == true
		if not held:
			body.global_position.y = clampf(body.global_position.y, stage_top, stage_bottom)
		if "_land_y" in actor:
			actor._land_y = clampf(float(actor._land_y), stage_top, stage_bottom)
	if "_home" in actor:
		var home: Vector2 = actor._home
		home.y = clampf(home.y, stage_top, stage_bottom)
		actor._home = home


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
	if countdown_label:
		countdown_label.text = ""
		countdown_label.modulate = Color(1, 1, 1, 1)
	await get_tree().create_timer(COUNTDOWN_BEAT, false).timeout
	if not is_instance_valid(self):
		return
	for n in [3, 2, 1]:
		_set_countdown_text(str(n), Color(1, 1, 1, 1))
		await get_tree().create_timer(COUNTDOWN_STEP, false).timeout
		if not is_instance_valid(self):
			return
	_set_countdown_text("GO", Color(1, 0.85, 0.2, 1))
	if is_instance_valid(player) and player.has_method("start_intro_drop"):
		player.start_intro_drop()
	await get_tree().create_timer(GO_HOLD, false).timeout
	if not is_instance_valid(level_banner):
		return
	var tween := create_tween()
	tween.tween_property(level_banner, "modulate:a", 0.0, BANNER_FADE)
	await tween.finished
	if is_instance_valid(level_banner):
		level_banner.hide()


func _set_countdown_text(value: String, color: Color) -> void:
	if countdown_label == null or not is_instance_valid(countdown_label):
		return
	countdown_label.text = value
	countdown_label.add_theme_color_override("font_color", color)


func _on_player_health_changed(current: int, maximum: int) -> void:
	if hud:
		hud.set_health(current, maximum)


func _on_enemy_scored(points: int) -> void:
	score += points
	if score < 0:
		score = 0
	if hud:
		hud.set_score(score)
	if score <= 0:
		_kill_from_zero_score()


func _kill_from_zero_score() -> void:
	if _exiting:
		return
	if player == null or not is_instance_valid(player) or player.dead:
		return
	player.kill()


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
	get_tree().change_scene_to_file(next_level_path)
