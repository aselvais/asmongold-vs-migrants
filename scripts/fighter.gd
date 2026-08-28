extends CharacterBody2D

const SPEED := 360.0
const STAGE_LEFT := 84.0
const STAGE_RIGHT := 6316.0
const STAGE_TOP := 1024.0 * 2.0 / 3.0
const STAGE_BOTTOM := 890.0
const BODY_HALF_WIDTH := 41.5
const STRIKE_FRAME_WIDTH := 166.0
const MAX_HITS := 5
const STRIKE_HIT_START := 2
const STRIKE_HIT_END := 5
const HITBOX_OFFSET_X := 58.0
const BLINK_COUNT := 2
const BLINK_STEP := 0.09

signal died

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var swoosh: AudioStreamPlayer = $Swoosh
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox

var move_speed := SPEED
var striking := false
var dead := false
var invulnerable := false
var hits := 0
var _hit_this_strike: Dictionary = {}


func _ready() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play(&"idle")
	hitbox.monitoring = false
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	_sync_sprite_offset()
	_sync_hitbox_side()


func start_strike() -> void:
	if dead or striking:
		return
	striking = true
	_hit_this_strike.clear()
	velocity = Vector2.ZERO
	sprite.play(&"strike")
	swoosh.play()
	_sync_sprite_offset()
	_sync_hitbox_side()


func take_hit(_from: Node) -> void:
	if dead or invulnerable:
		return
	invulnerable = true
	hits += 1
	striking = false
	_set_hitbox_active(false)
	_play(&"idle")
	_sync_sprite_offset()
	await _blink()
	if not is_instance_valid(self):
		return
	if hits >= MAX_HITS:
		_die()
	else:
		invulnerable = false


func _die() -> void:
	if dead:
		return
	dead = true
	striking = false
	invulnerable = true
	velocity = Vector2.ZERO
	_set_hitbox_active(false)
	hurtbox.set_deferred("monitorable", false)
	sprite.visible = true
	sprite.pause()
	died.emit()


func _apply_move(direction: Vector2) -> void:
	if dead:
		velocity = Vector2.ZERO
		return

	if striking:
		velocity = Vector2.ZERO
	else:
		velocity = direction * move_speed
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		if direction != Vector2.ZERO:
			_play(&"walk")
		else:
			_play(&"idle")
		_sync_sprite_offset()
		_sync_hitbox_side()

	move_and_slide()
	global_position.x = clampf(global_position.x, STAGE_LEFT, STAGE_RIGHT)
	global_position.y = clampf(global_position.y, STAGE_TOP, STAGE_BOTTOM)
	z_index = int(global_position.y)
	_update_hitbox()


func _update_hitbox() -> void:
	if not striking or dead:
		_set_hitbox_active(false)
		return
	var frame := sprite.frame
	_set_hitbox_active(frame >= STRIKE_HIT_START and frame <= STRIKE_HIT_END)


func _set_hitbox_active(active: bool) -> void:
	if hitbox.monitoring == active:
		return
	hitbox.monitoring = active
	if not active:
		return
	_sync_hitbox_side()
	for area in hitbox.get_overlapping_areas():
		_on_hitbox_area_entered(area)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not striking or dead:
		return
	var other := area.get_parent()
	if other == self or not other.has_method("take_hit"):
		return
	var vs_enemy := is_in_group("player") and other.is_in_group("enemies")
	var vs_player := is_in_group("enemies") and other.is_in_group("player")
	if not vs_enemy and not vs_player:
		return
	var other_id := other.get_instance_id()
	if _hit_this_strike.has(other_id):
		return
	_hit_this_strike[other_id] = true
	other.take_hit(self)


func _on_animation_finished() -> void:
	if sprite.animation != &"strike":
		return
	striking = false
	_set_hitbox_active(false)
	if dead:
		return
	_play(&"idle")
	_sync_sprite_offset()


func _play(anim: StringName) -> void:
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func _sync_sprite_offset() -> void:
	var frame_width := STRIKE_FRAME_WIDTH if sprite.animation == &"strike" else BODY_HALF_WIDTH * 2.0
	var shift := frame_width * 0.5 - BODY_HALF_WIDTH
	sprite.offset.x = -shift if sprite.flip_h else shift


func _sync_hitbox_side() -> void:
	hitbox.position.x = -HITBOX_OFFSET_X if sprite.flip_h else HITBOX_OFFSET_X


func _blink() -> void:
	invulnerable = true
	for _i in BLINK_COUNT:
		if not is_instance_valid(self):
			return
		sprite.visible = false
		await get_tree().create_timer(BLINK_STEP).timeout
		if not is_instance_valid(self):
			return
		sprite.visible = true
		await get_tree().create_timer(BLINK_STEP).timeout
	if is_instance_valid(self):
		sprite.visible = true
