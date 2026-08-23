extends CharacterBody2D

const SPEED := 360.0
const STAGE_LEFT := 84.0
const STAGE_RIGHT := 6316.0
const STAGE_TOP := 1024.0 * 2.0 / 3.0
const STAGE_BOTTOM := 890.0
const BODY_HALF_WIDTH := 41.5
const STRIKE_FRAME_WIDTH := 166.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var swoosh: AudioStreamPlayer = $Swoosh

var striking := false


func _ready() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play(&"idle")
	_sync_sprite_offset()


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"strike") and not striking:
		_start_strike()

	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

	if striking:
		velocity = Vector2.ZERO
	else:
		velocity = direction * SPEED
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		if direction != Vector2.ZERO:
			_play(&"walk")
		else:
			_play(&"idle")
		_sync_sprite_offset()

	move_and_slide()
	global_position.x = clampf(global_position.x, STAGE_LEFT, STAGE_RIGHT)
	global_position.y = clampf(global_position.y, STAGE_TOP, STAGE_BOTTOM)


func _start_strike() -> void:
	striking = true
	velocity = Vector2.ZERO
	sprite.play(&"strike")
	swoosh.play()
	_sync_sprite_offset()


func _on_animation_finished() -> void:
	if sprite.animation != &"strike":
		return
	striking = false
	_play(&"idle")
	_sync_sprite_offset()


func _play(anim: StringName) -> void:
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func _sync_sprite_offset() -> void:
	var frame_width := STRIKE_FRAME_WIDTH if sprite.animation == &"strike" else BODY_HALF_WIDTH * 2.0
	var shift := frame_width * 0.5 - BODY_HALF_WIDTH
	sprite.offset.x = -shift if sprite.flip_h else shift
