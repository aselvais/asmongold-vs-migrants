extends CharacterBody2D

const SPEED := 360.0
const DEFAULT_STAGE_LEFT := 84.0
const DEFAULT_STAGE_RIGHT := 6316.0
const DEFAULT_STAGE_TOP := 1024.0 * 2.0 / 3.0
const DEFAULT_STAGE_BOTTOM := 890.0

var STAGE_LEFT := DEFAULT_STAGE_LEFT
var STAGE_RIGHT := DEFAULT_STAGE_RIGHT
var STAGE_TOP := DEFAULT_STAGE_TOP
var STAGE_BOTTOM := DEFAULT_STAGE_BOTTOM
const BODY_HALF_WIDTH := 41.5
const MAX_HITS := 5
const STRIKE_HIT_START := 2
const STRIKE_HIT_END := 5
const HITBOX_OFFSET_X := 58.0
const BLINK_COUNT := 2
const BLINK_STEP := 0.09
const PUNCH_STREAM := preload("res://assets/sfx/punch.wav")

signal died
signal health_changed(current: int, maximum: int)

@export var max_hits: int = MAX_HITS
@export var strike_sfx_on_start: bool = true
@export var strike_stream: AudioStream

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
	_apply_strike_stream()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)
	_play(&"idle")
	hitbox.monitoring = false
	if not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		hitbox.area_entered.connect(_on_hitbox_area_entered)
	_sync_sprite_offset()
	_sync_hitbox_side()
	health_changed.emit(current_health(), max_hits)


func current_health() -> int:
	return maxi(0, max_hits - hits)


func _apply_strike_stream() -> void:
	if swoosh == null:
		return
	if strike_stream:
		swoosh.stream = strike_stream
	if GameSettings.OFFENCIVE_MODE:
		return
	if swoosh.stream and swoosh.stream.resource_path.ends_with("wakbar.wav"):
		swoosh.stream = PUNCH_STREAM


func start_strike() -> void:
	if dead or striking:
		return
	if not _has_anim(&"strike"):
		return
	striking = true
	_hit_this_strike.clear()
	velocity = Vector2.ZERO
	sprite.play(&"strike")
	if strike_sfx_on_start and swoosh:
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
	health_changed.emit(current_health(), max_hits)
	await _blink()
	if not is_instance_valid(self):
		return
	if hits >= max_hits:
		_die()
	else:
		invulnerable = false


func kill() -> void:
	if dead:
		return
	_die()


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
	health_changed.emit(current_health(), max_hits)
	died.emit()


func revive() -> void:
	dead = false
	striking = false
	invulnerable = true
	hits = 0
	velocity = Vector2.ZERO
	_set_hitbox_active(false)
	hurtbox.monitorable = true
	sprite.visible = true
	sprite.modulate.a = 1.0
	_play(&"idle")
	_sync_sprite_offset()
	_sync_hitbox_side()
	health_changed.emit(current_health(), max_hits)
	await _blink()
	if not is_instance_valid(self) or dead:
		return
	invulnerable = false


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
	var count := 0
	if sprite.sprite_frames:
		count = sprite.sprite_frames.get_frame_count(sprite.animation)
	var start := STRIKE_HIT_START
	var end := STRIKE_HIT_END
	if count > 0:
		start = maxi(1, int(count / 3.0))
		end = maxi(start, int((count * 2) / 3.0))
	_set_hitbox_active(frame >= start and frame <= end)


func _set_hitbox_active(active: bool) -> void:
	if hitbox.monitoring == active:
		return
	hitbox.monitoring = active
	if not active:
		return
	if not strike_sfx_on_start and swoosh:
		swoosh.play()
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
	if not _has_anim(anim):
		return
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func _has_anim(anim: StringName) -> bool:
	return sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim)


func _frame_width(anim: StringName = &"", frame: int = -1) -> float:
	var frames := sprite.sprite_frames
	if frames == null:
		return BODY_HALF_WIDTH * 2.0
	var anim_name := anim if anim != &"" else sprite.animation
	if not frames.has_animation(anim_name):
		return BODY_HALF_WIDTH * 2.0
	var idx := frame if frame >= 0 else sprite.frame
	var tex := frames.get_frame_texture(anim_name, idx)
	if tex == null:
		return BODY_HALF_WIDTH * 2.0
	return float(tex.get_width())


func _sync_sprite_offset() -> void:
	var body_width := _frame_width(&"idle", 0)
	var frame_width := _frame_width()
	var shift := frame_width * 0.5 - body_width * 0.5
	sprite.offset.x = -shift if sprite.flip_h else shift


func _sync_hitbox_side() -> void:
	var body_width := _frame_width(&"idle", 0)
	var offset_x := maxf(HITBOX_OFFSET_X * (body_width / (BODY_HALF_WIDTH * 2.0)), 40.0)
	hitbox.position.x = -offset_x if sprite.flip_h else offset_x


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
