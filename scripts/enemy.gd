extends "res://scripts/fighter.gd"

const ATTACK_RANGE_X := 140.0
const ATTACK_RANGE_Y := 48.0
const STRIKE_COOLDOWN := 0.75

var _cooldown := 0.6
var _player: Node2D


func _ready() -> void:
	add_to_group("enemies")
	super._ready()
	move_speed = 280.0
	modulate = Color(1.0, 0.42, 0.42, 1.0)
	sprite.flip_h = true
	_sync_sprite_offset()
	_sync_hitbox_side()
	_player = get_tree().get_first_node_in_group("player") as Node2D


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
		_apply_move(Vector2.ZERO)
		return

	var to_player: Vector2 = _player.global_position - global_position
	var in_range := absf(to_player.x) <= ATTACK_RANGE_X and absf(to_player.y) <= ATTACK_RANGE_Y
	if in_range:
		sprite.flip_h = to_player.x < 0.0
		_sync_sprite_offset()
		_sync_hitbox_side()
		if _cooldown <= 0.0:
			start_strike()
			_cooldown = STRIKE_COOLDOWN
		else:
			_apply_move(Vector2.ZERO)
		return

	var direction := Vector2.ZERO
	if absf(to_player.x) > ATTACK_RANGE_X * 0.45:
		direction.x = signf(to_player.x)
	if absf(to_player.y) > ATTACK_RANGE_Y * 0.35:
		direction.y = signf(to_player.y)
	_apply_move(direction)


func _die() -> void:
	super._die()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.45)
	await tween.finished
	if is_instance_valid(self):
		queue_free()
