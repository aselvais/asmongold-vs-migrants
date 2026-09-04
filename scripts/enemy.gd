extends "res://scripts/fighter.gd"

const ATTACK_RANGE_X := 140.0
const ATTACK_RANGE_Y := 48.0
const STRIKE_COOLDOWN := 1.2
const AGGRO_RANGE_X := 220.0
const AGGRO_RANGE_Y := 72.0
const WANDER_CHANGE_MIN := 0.7
const WANDER_CHANGE_MAX := 2.0
const WANDER_RADIUS := 180.0
const SPEECH_DURATION := 1.5
const SPEECH_MAX_WIDTH := 220.0
const SPEECH_FILL := Color(1.0, 1.0, 0.94)
const SPEECH_BORDER := Color(0.08, 0.08, 0.1)
const SCORE_POPUP_DURATION := 1.0
const SCORE_POPUP_RISE := 80.0
const SCORE_POSITIVE := Color(0.22, 0.92, 0.28, 1)
const SCORE_NEGATIVE := Color(0.95, 0.16, 0.12, 1)
const SCORE_FONT := preload("res://assets/fonts/PressStart2P-Regular.ttf")

signal scored(points: int)

@export var sprite_frames_override: SpriteFrames
@export var walk_speed: float = 240.0
@export var score_value: int = 100
@export var strike_speech: String = ""
@export var can_attack: bool = true

var _cooldown := 0.8
var _player: Node2D
var _wander_dir := Vector2.ZERO
var _wander_timer := 0.0
var _home := Vector2.ZERO
var _speech: Node2D
var _speech_label: Label
var _speech_timer: Timer


func _ready() -> void:
	add_to_group("enemies")
	if GameSettings.roles_flipped():
		can_attack = not can_attack
		score_value = -score_value
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
	_setup_speech_bubble()


func _physics_process(delta: float) -> void:
	if _speech and _speech.visible:
		_sync_speech_position()
	if dead:
		velocity = Vector2.ZERO
		return
	if _cooldown > 0.0:
		_cooldown -= delta
	if striking or invulnerable:
		_apply_move(Vector2.ZERO)
		return

	if _player == null or not is_instance_valid(_player) or bool(_player.get("dead")) or not can_attack:
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


func _setup_speech_bubble() -> void:
	if not GameSettings.OFFENCIVE_MODE:
		return
	if strike_speech.is_empty():
		return

	_speech = Node2D.new()
	_speech.name = "SpeechBubble"
	_speech.visible = false
	_speech.z_as_relative = false
	_speech.z_index = 4096
	add_child(_speech)
	_sync_speech_position()

	var tail_outline := Polygon2D.new()
	tail_outline.name = "TailOutline"
	tail_outline.color = SPEECH_FILL
	tail_outline.polygon = PackedVector2Array([
		Vector2(-7.0, -2.0),
		Vector2(7.0, -2.0),
		Vector2(0.0, 12.0),
	])
	_speech.add_child(tail_outline)

	var tail := Polygon2D.new()
	tail.name = "Tail"
	tail.color = SPEECH_FILL
	tail.polygon = PackedVector2Array([
		Vector2(-5.0, -3.0),
		Vector2(5.0, -3.0),
		Vector2(0.0, 9.0),
	])
	_speech.add_child(tail)

	_speech_label = Label.new()
	_speech_label.name = "Text"
	_speech_label.text = strike_speech
	_speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speech_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_speech_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speech_label.add_theme_font_size_override("font_size", 8)
	_speech_label.add_theme_color_override("font_color", SPEECH_BORDER)
	_speech_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	_speech_label.add_theme_constant_override("outline_size", 0)
	var style := StyleBoxFlat.new()
	style.bg_color = SPEECH_FILL
	style.border_color = SPEECH_FILL
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	_speech_label.add_theme_stylebox_override("normal", style)
	_speech.add_child(_speech_label)
	call_deferred("_layout_speech_bubble")

	_speech_timer = Timer.new()
	_speech_timer.name = "SpeechTimer"
	_speech_timer.one_shot = true
	_speech_timer.wait_time = SPEECH_DURATION
	_speech_timer.timeout.connect(_hide_strike_speech)
	add_child(_speech_timer)


func _layout_speech_bubble() -> void:
	if _speech_label == null:
		return
	_speech_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_speech_label.custom_minimum_size = Vector2.ZERO
	var size := _speech_label.get_combined_minimum_size()
	if size.x > SPEECH_MAX_WIDTH:
		_speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_speech_label.custom_minimum_size = Vector2(SPEECH_MAX_WIDTH, 0)
		size = _speech_label.get_combined_minimum_size()
		size.x = SPEECH_MAX_WIDTH
	_speech_label.size = size
	_speech_label.position = Vector2(-size.x * 0.5, -size.y)


func _frame_height(anim: StringName = &"", frame: int = -1) -> float:
	var frames := sprite.sprite_frames
	if frames == null:
		return 128.0
	var anim_name := anim if anim != &"" else sprite.animation
	if not frames.has_animation(anim_name):
		return 128.0
	var idx := frame if frame >= 0 else sprite.frame
	var tex := frames.get_frame_texture(anim_name, idx)
	if tex == null:
		return 128.0
	return float(tex.get_height())


func _sync_speech_position() -> void:
	if _speech == null:
		return
	var height := _frame_height(&"idle", 0)
	_speech.position = Vector2(sprite.offset.x, -height * 0.5 - 20.0)


func _show_strike_speech() -> void:
	if not GameSettings.OFFENCIVE_MODE:
		return
	if _speech == null:
		return
	_layout_speech_bubble()
	_sync_speech_position()
	_speech.visible = true
	if _speech_timer:
		_speech_timer.start(SPEECH_DURATION)


func _hide_strike_speech() -> void:
	if _speech:
		_speech.visible = false
	if _speech_timer:
		_speech_timer.stop()


func take_hit(from: Node) -> void:
	if dead or invulnerable:
		return
	scored.emit(score_value)
	_spawn_score_popup()
	if _speaks_on_hit():
		_show_strike_speech()
	await super.take_hit(from)


func start_strike() -> void:
	if not can_attack:
		return
	super.start_strike()
	if striking:
		_show_strike_speech()


func _speaks_on_hit() -> bool:
	return not can_attack and score_value < 0 and not strike_speech.is_empty()


func _spawn_score_popup() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return

	var popup := Node2D.new()
	popup.name = "ScorePopup"
	popup.z_as_relative = false
	popup.z_index = 4096
	tree.current_scene.add_child(popup)

	var height := _frame_height(&"idle", 0) * scale.y
	popup.global_position = global_position + Vector2(52.0, -height * 0.42)

	var label := Label.new()
	label.text = "%+d" % score_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", SCORE_FONT)
	label.add_theme_font_size_override("font_size", 20)
	var color := SCORE_POSITIVE if score_value >= 0 else SCORE_NEGATIVE
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 6)
	popup.add_child(label)
	label.reset_size()
	var size := label.get_combined_minimum_size()
	label.size = size
	label.position = Vector2(-size.x * 0.5, -size.y)

	var tween := popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "global_position:y", popup.global_position.y - SCORE_POPUP_RISE, SCORE_POPUP_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, SCORE_POPUP_DURATION)
	tween.chain().tween_callback(popup.queue_free)


func _die() -> void:
	_hide_strike_speech()
	super._die()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.45)
	await tween.finished
	if is_instance_valid(self):
		queue_free()
