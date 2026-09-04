extends "res://scripts/fighter.gd"

const DROP_START_Y := -140.0
const DROP_GRAVITY := 2800.0
const DROP_START_SPEED := 120.0
const RESPAWN_BLINK_TIME := 2.0
const VANISH_TIME := 0.45
const KNOCKBACK_SPEED_X := 400.0
const KNOCKBACK_SPEED_Y := -700.0
const KNOCKBACK_GRAVITY := 2600.0

var dropping_in := false
var respawning := false
var knockback := false
var exiting := false
var _exit_walk_target := Vector2.ZERO
var _exit_walking := false
var _drop_velocity := 0.0
var _land_y := 820.0
var _blink_until_msec := 0
var _knock_vel := Vector2.ZERO
var _knock_land_y := 820.0


func _ready() -> void:
	add_to_group("player")
	super._ready()
	_begin_sky_drop(false)


func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return
	if exiting:
		if _exit_walking:
			_process_exit_walk()
		return
	if knockback:
		_process_knockback(delta)
		return
	if respawning:
		_update_respawn_blink()
	if dropping_in:
		_process_drop(delta)
		return
	if respawning and _blink_until_msec <= 0:
		velocity = Vector2.ZERO
		return
	if Input.is_action_just_pressed(&"strike") and not striking:
		start_strike()
	var direction := Vector2.ZERO
	if not striking:
		direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_apply_move(direction)


func take_hit(from: Node) -> void:
	if dead or invulnerable or respawning or dropping_in or knockback or exiting:
		return
	_start_knockback(from)
	await super.take_hit(from)
	if not is_instance_valid(self) or dead:
		return
	if knockback:
		invulnerable = true
		while knockback and is_instance_valid(self) and not dead:
			await get_tree().physics_frame
	if is_instance_valid(self) and not dead and hits < max_hits:
		invulnerable = false


func _die() -> void:
	knockback = false
	sprite.visible = false
	super._die()


func revive() -> void:
	hits = 0
	health_changed.emit(current_health(), max_hits)
	await _begin_sky_drop(true)


func _begin_sky_drop(vanish_first: bool) -> void:
	_land_y = clampf(global_position.y, STAGE_TOP, STAGE_BOTTOM)
	dead = false
	striking = false
	invulnerable = true
	respawning = true
	dropping_in = false
	knockback = false
	velocity = Vector2.ZERO
	_drop_velocity = 0.0
	_blink_until_msec = 0
	_set_hitbox_active(false)
	hurtbox.monitorable = false
	sprite.visible = false
	sprite.modulate.a = 1.0

	if vanish_first:
		await get_tree().create_timer(VANISH_TIME).timeout
		if not is_instance_valid(self) or dead:
			return

	global_position.y = DROP_START_Y
	_drop_velocity = DROP_START_SPEED
	dropping_in = true
	z_index = 4000
	_play(&"idle")
	sprite.visible = true

	while dropping_in and is_instance_valid(self) and not dead:
		await get_tree().physics_frame
	if not is_instance_valid(self) or dead:
		return

	_blink_until_msec = Time.get_ticks_msec() + int(RESPAWN_BLINK_TIME * 1000.0)
	while is_instance_valid(self) and not dead and Time.get_ticks_msec() < _blink_until_msec:
		await get_tree().physics_frame
	if not is_instance_valid(self) or dead:
		return

	sprite.visible = true
	hurtbox.monitorable = true
	respawning = false
	_blink_until_msec = 0
	invulnerable = false


func _process_drop(delta: float) -> void:
	_drop_velocity += DROP_GRAVITY * delta
	global_position.y += _drop_velocity * delta
	global_position.x = clampf(global_position.x, STAGE_LEFT, STAGE_RIGHT)
	z_index = 4000
	if global_position.y >= _land_y:
		global_position.y = _land_y
		velocity = Vector2.ZERO
		z_index = int(global_position.y)
		dropping_in = false


func _start_knockback(from: Node) -> void:
	_knock_land_y = clampf(global_position.y, STAGE_TOP, STAGE_BOTTOM)
	var dir := -1.0 if sprite.flip_h else 1.0
	if from is Node2D and is_instance_valid(from):
		var dx := global_position.x - (from as Node2D).global_position.x
		if dx != 0.0:
			dir = signf(dx)
		sprite.flip_h = dx < 0.0
	_knock_vel = Vector2(dir * KNOCKBACK_SPEED_X, KNOCKBACK_SPEED_Y)
	knockback = true
	striking = false
	velocity = Vector2.ZERO
	_set_hitbox_active(false)
	_sync_sprite_offset()
	_sync_hitbox_side()


func _process_knockback(delta: float) -> void:
	_knock_vel.y += KNOCKBACK_GRAVITY * delta
	global_position += _knock_vel * delta
	global_position.x = clampf(global_position.x, STAGE_LEFT, STAGE_RIGHT)
	if global_position.y >= _knock_land_y:
		global_position.y = _knock_land_y
		_knock_vel = Vector2.ZERO
		knockback = false
	z_index = int(global_position.y)


func walk_into_stairs(stairs_pos: Vector2) -> void:
	exiting = true
	_exit_walking = true
	invulnerable = true
	striking = false
	knockback = false
	dropping_in = false
	respawning = false
	velocity = Vector2.ZERO
	_set_hitbox_active(false)
	hurtbox.monitorable = false
	sprite.visible = true
	sprite.modulate.a = 1.0
	_exit_walk_target = Vector2(stairs_pos.x, clampf(global_position.y, STAGE_TOP, STAGE_BOTTOM))

	while is_instance_valid(self) and not dead and _exit_walking:
		await get_tree().physics_frame
	if not is_instance_valid(self) or dead:
		return

	global_position = _exit_walk_target
	_play(&"walk")
	sprite.flip_h = stairs_pos.x < global_position.x
	_sync_sprite_offset()
	z_index = 900
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", stairs_pos, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", scale * 0.42, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.85).set_delay(0.35)
	await tween.finished


func _process_exit_walk() -> void:
	var to_target := _exit_walk_target - global_position
	if to_target.length() <= 14.0:
		velocity = Vector2.ZERO
		_exit_walking = false
		return
	var dir := Vector2.ZERO
	if absf(to_target.x) > 6.0:
		dir.x = signf(to_target.x)
	if absf(to_target.y) > 6.0:
		dir.y = signf(to_target.y)
	_apply_move(dir)


func _update_respawn_blink() -> void:
	if _blink_until_msec <= 0:
		return
	if Time.get_ticks_msec() >= _blink_until_msec:
		sprite.visible = true
		return
	var step_ms := int(BLINK_STEP * 1000.0)
	if step_ms <= 0:
		step_ms = 90
	sprite.visible = (Time.get_ticks_msec() % (step_ms * 2)) < step_ms
