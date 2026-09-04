extends Control

@onready var health_bar: ProgressBar = $Margin/Row/PlayerBlock/HealthBar
@onready var lives_label: Label = $Margin/Row/PlayerBlock/Lives
@onready var score_value: Label = $Margin/Row/ScoreBlock/ScoreValue

var _fill_style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_health_bar()


func set_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	if _fill_style == null:
		return
	var ratio := 1.0 if maximum <= 0 else float(current) / float(maximum)
	if ratio <= 0.34:
		_fill_style.bg_color = Color(0.92, 0.16, 0.12, 1)
	elif ratio <= 0.6:
		_fill_style.bg_color = Color(0.95, 0.72, 0.12, 1)
	else:
		_fill_style.bg_color = Color(0.22, 0.82, 0.28, 1)


func set_lives(lives: int, _maximum: int = 3) -> void:
	lives_label.text = "LIVES x %d" % lives


func set_score(score: int) -> void:
	if score < 0:
		score_value.text = "-%06d" % absi(score)
	else:
		score_value.text = "%06d" % score


func _style_health_bar() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.07, 0.03, 0.03, 0.95)
	bg.set_border_width_all(2)
	bg.border_color = Color(0.95, 0.82, 0.2, 1)
	bg.set_corner_radius_all(2)
	bg.content_margin_left = 3
	bg.content_margin_top = 3
	bg.content_margin_right = 3
	bg.content_margin_bottom = 3
	_fill_style = StyleBoxFlat.new()
	_fill_style.bg_color = Color(0.22, 0.82, 0.28, 1)
	_fill_style.set_corner_radius_all(1)
	health_bar.add_theme_stylebox_override("background", bg)
	health_bar.add_theme_stylebox_override("fill", _fill_style)
	health_bar.show_percentage = false
