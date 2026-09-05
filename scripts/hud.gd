extends Control

@onready var health_bar: ProgressBar = $Margin/Row/PlayerBlock/HealthBar
@onready var lives_label: Label = $Margin/Row/PlayerBlock/Lives
@onready var score_block: VBoxContainer = $Margin/Row/ScoreBlock
@onready var score_value: Label = $Margin/Row/ScoreBlock/ScoreValue

var _fill_style: StyleBoxFlat
var _volume_slider: HSlider


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_health_bar()
	_setup_volume_slider()


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


func _setup_volume_slider() -> void:
	if score_block == null:
		return
	if score_block.has_node("VolumeBlock"):
		_volume_slider = score_block.get_node("VolumeBlock/VolumeSlider") as HSlider
	else:
		var block := HBoxContainer.new()
		block.name = "VolumeBlock"
		block.mouse_filter = Control.MOUSE_FILTER_STOP
		block.alignment = BoxContainer.ALIGNMENT_END
		block.add_theme_constant_override("separation", 10)
		var label := Label.new()
		label.text = "MUSIC"
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_font_size_override("font_size", 16)
		_volume_slider = HSlider.new()
		_volume_slider.name = "VolumeSlider"
		_volume_slider.min_value = 0.0
		_volume_slider.max_value = 1.0
		_volume_slider.step = 0.01
		_volume_slider.custom_minimum_size = Vector2(140, 18)
		_volume_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_volume_slider.focus_mode = Control.FOCUS_NONE
		_volume_slider.mouse_filter = Control.MOUSE_FILTER_STOP
		_volume_slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		block.add_child(label)
		block.add_child(_volume_slider)
		score_block.add_child(block)
		score_block.move_child(block, 0)
	_style_volume_slider(_volume_slider)
	_volume_slider.set_value_no_signal(GameSettings.music_volume)
	if not _volume_slider.value_changed.is_connected(_on_music_volume_changed):
		_volume_slider.value_changed.connect(_on_music_volume_changed)
	if not GameSettings.music_volume_changed.is_connected(_on_settings_music_volume_changed):
		GameSettings.music_volume_changed.connect(_on_settings_music_volume_changed)


func _on_music_volume_changed(value: float) -> void:
	GameSettings.set_music_volume(value)


func _on_settings_music_volume_changed(linear: float) -> void:
	if _volume_slider and not is_equal_approx(_volume_slider.value, linear):
		_volume_slider.set_value_no_signal(linear)


func _style_volume_slider(slider: HSlider) -> void:
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color(0.07, 0.03, 0.03, 0.95)
	groove.set_border_width_all(2)
	groove.border_color = Color(0.95, 0.82, 0.2, 1)
	groove.set_corner_radius_all(2)
	groove.content_margin_top = 5
	groove.content_margin_bottom = 5
	groove.content_margin_left = 6
	groove.content_margin_right = 6
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1, 0.85, 0.2, 1)
	fill.set_corner_radius_all(1)
	slider.add_theme_stylebox_override("slider", groove)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	var grabber := _make_slider_grabber()
	slider.add_theme_icon_override("grabber", grabber)
	slider.add_theme_icon_override("grabber_highlight", grabber)


func _make_slider_grabber() -> Texture2D:
	var img := Image.create(12, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0.85, 0.2, 1))
	var edge := Color(0.05, 0.02, 0.02, 1)
	for x in 12:
		img.set_pixel(x, 0, edge)
		img.set_pixel(x, 17, edge)
	for y in 18:
		img.set_pixel(0, y, edge)
		img.set_pixel(11, y, edge)
	return ImageTexture.create_from_image(img)


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
