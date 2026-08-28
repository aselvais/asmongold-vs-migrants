extends "res://scripts/fighter.gd"


func _ready() -> void:
	add_to_group("player")
	super._ready()


func _physics_process(_delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return
	if Input.is_action_just_pressed(&"strike") and not striking:
		start_strike()
	var direction := Vector2.ZERO
	if not striking:
		direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_apply_move(direction)
