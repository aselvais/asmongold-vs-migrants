extends "res://scripts/fighter.gd"

const ATTACK_RANGE_X := 140.0
const ATTACK_RANGE_Y := 48.0
const STRIKE_COOLDOWN := 1.2
const AGGRO_RANGE_X := 220.0
const AGGRO_RANGE_Y := 72.0
const WANDER_CHANGE_MIN := 0.7
const WANDER_CHANGE_MAX := 2.0
const WANDER_RADIUS := 180.0

@export var sprite_frames_override: SpriteFrames
@export var walk_speed: float = 240.0
@export var score_value: int = 100

var _cooldown := 0.8
var _player: Node2D
var _wander_dir := Vector2.ZERO
var _wander_timer := 0.0
var _home := Vector2.ZERO


func _ready() -> void:
	add_to_group("enemies")
	if sprite_frames_override:
		$AnimatedSprite2D.sprite_frames = sprite_frames_override
	super._ready()
	move_speed = walk_speed
	sprite.flip_h = true
	_sync_sprite_offset()
	_sync_hitbox_side()
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_home = global_position
	_pick_wander()


func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return
	if _cooldown > 0.0:
		_cooldown -= delta
	if striking or invulnerable:
		_apply_move(Vector2.ZERO)
		return

	if _player == null or not is_instance_valid(_player) or bool(_player.get("dead")):
		_wander(delta)
		return

	var to_player: Vector2 = _player.global_position - global_position
	var in_range := absf(to_player.x) <= ATTACK_RANGE_X and absf(to_player.y) <= ATTACK_RANGE_Y
	if in_range:
		sprite.flip_h = to_player.x < 0.0
		_sync_sprite_offset()
		_sync_hitbox_side()
		if _cooldown <= 0.0 and _has_anim(&"strike"):
			start_strike()
			_cooldown = STRIKE_COOLDOWN
		else:
			_apply_move(Vector2.ZERO)
		return

	var aggro := absf(to_player.x) <= AGGRO_RANGE_X and absf(to_player.y) <= AGGRO_RANGE_Y
	if aggro:
		var direction := Vector2.ZERO
		if absf(to_player.x) > ATTACK_RANGE_X * 0.45:
			direction.x = signf(to_player.x)
		if absf(to_player.y) > ATTACK_RANGE_Y * 0.35:
			direction.y = signf(to_player.y)
		_apply_move(direction)
		return

	_wander(delta)


func _wander(delta: float) -> void:
	var to_home: Vector2 = _home - global_position
	if to_home.length() > WANDER_RADIUS:
		_wander_dir = to_home.normalized()
		_wander_timer = 0.35
		_apply_move(_wander_dir)
		return
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_wander()
	_apply_move(_wander_dir)


func _pick_wander() -> void:
	_wander_timer = randf_range(WANDER_CHANGE_MIN, WANDER_CHANGE_MAX)
	var roll := randi() % 7
	match roll:
		0:
			_wander_dir = Vector2.LEFT
		1:
			_wander_dir = Vector2.RIGHT
		2:
			_wander_dir = Vector2.ZERO
		3:
			_wander_dir = Vector2(1.0, 0.35).normalized()
		4:
			_wander_dir = Vector2(-1.0, 0.35).normalized()
		5:
			_wander_dir = Vector2(1.0, -0.35).normalized()
		_:
			_wander_dir = Vector2(-1.0, -0.35).normalized()


func _die() -> void:
	super._die()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.45)
	await tween.finished
	if is_instance_valid(self):
		queue_free()
