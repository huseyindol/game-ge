extends Node2D
## LevelScene — 24 seviyenin tümünü çalıştıran tek sahne.
##
## LevelManager state'i tutar; biz onu DİNLER ve görselleştiririz.
## Genişlik > yükseklik ise yatay düzen (sol bilgi şeridi + sağ seçenekler).

@onready var background: ColorRect = $Background
@onready var choices_container: GridContainer = %ChoicesContainer
@onready var confetti: CPUParticles2D = $FXLayer/Confetti
@onready var bubble_text: Label = $FXLayer/BubbleText
@onready var main_layout: MarginContainer = $HUD/MainLayout
@onready var root_vbox: VBoxContainer = $HUD/MainLayout/RootVBox
@onready var top_block: VBoxContainer = $HUD/MainLayout/RootVBox/TopBlock
@onready var choices_center: CenterContainer = $HUD/MainLayout/RootVBox/ChoicesCenter

const CHOICE_GRID_4 := 2
const CHOICE_GRID_6 := 3

var _choice_nodes: Array[Choice] = []
var _root_hbox: HBoxContainer = null


func _ready() -> void:
	LevelManager.level_started.connect(_on_level_started)
	LevelManager.answer_evaluated.connect(_on_answer_evaluated)
	bubble_text.visible = false
	confetti.emitting = false

	get_viewport().size_changed.connect(_on_viewport_changed)
	_on_viewport_changed()

	LevelManager.enter_current_level()


func _on_viewport_changed() -> void:
	_sync_viewport_nodes()
	_apply_play_area_layout()


func _sync_viewport_nodes() -> void:
	var sz := get_viewport().get_visible_rect().size
	if sz.x < 16.0 or sz.y < 16.0:
		return

	background.offset_left = 0.0
	background.offset_top = 0.0
	background.offset_right = sz.x
	background.offset_bottom = sz.y

	confetti.position = Vector2(sz.x * 0.5, sz.y * 0.88)
	confetti.emission_rect_extents = Vector2(minf(sz.x * 0.45, 360.0), 36.0)

	bubble_text.offset_left = 0.0
	bubble_text.offset_right = sz.x
	bubble_text.offset_top = sz.y * 0.42
	bubble_text.offset_bottom = sz.y * 0.62


func _ensure_landscape_strip() -> void:
	if _root_hbox != null:
		return
	_root_hbox = HBoxContainer.new()
	_root_hbox.name = "RootHBox"
	_root_hbox.add_theme_constant_override("separation", 20)
	main_layout.add_child(_root_hbox)
	_root_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)


func _apply_play_area_layout() -> void:
	var sz := get_viewport().get_visible_rect().size
	if sz.x < 16.0 or sz.y < 16.0:
		return
	var portrait := sz.y >= sz.x

	if portrait:
		if top_block.get_parent() != root_vbox:
			top_block.reparent(root_vbox)
			choices_center.reparent(root_vbox)
		root_vbox.visible = true
		if _root_hbox != null:
			_root_hbox.visible = false

		top_block.custom_minimum_size = Vector2.ZERO
		top_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_block.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		choices_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choices_center.size_flags_vertical = Control.SIZE_EXPAND_FILL

	else:
		_ensure_landscape_strip()
		if top_block.get_parent() != _root_hbox:
			top_block.reparent(_root_hbox)
			choices_center.reparent(_root_hbox)
		root_vbox.visible = false
		_root_hbox.visible = true

		var stripe_w := clampf(sz.x * 0.34, 216.0, 380.0)
		top_block.custom_minimum_size = Vector2(stripe_w, 0.0)
		top_block.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		top_block.size_flags_vertical = Control.SIZE_EXPAND_FILL
		choices_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choices_center.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _on_level_started(level: Dictionary, choice_keys: Array) -> void:
	_clear_choices()
	choices_container.columns = CHOICE_GRID_6 if level.choices == 6 else CHOICE_GRID_4

	for key in choice_keys:
		var c := _build_choice_for(level, key)
		choices_container.add_child(c)
		c.chose.connect(_on_choice_chose)
		_choice_nodes.append(c)

	AudioManager.speak_word(GameData.get_display_name(level))


func _clear_choices() -> void:
	for c in _choice_nodes:
		c.queue_free()
	_choice_nodes.clear()


func _build_choice_for(level: Dictionary, key: String) -> Choice:
	var c: Choice = preload("res://scenes/Choice.tscn").instantiate()
	match level.type:
		"color_circle":
			c.configure(key, Choice.Kind.CIRCLE,
				GameData.COLORS[key].hex, "", null)
		"color_text":
			c.configure(key, Choice.Kind.TEXT,
				GameData.COLORS[key].hex, GameData.COLORS[key].tr, null)
		"color_mixed":
			var as_text := randi() % 2 == 0
			if as_text:
				c.configure(key, Choice.Kind.TEXT,
					GameData.COLORS[key].hex, GameData.COLORS[key].tr, null)
			else:
				c.configure(key, Choice.Kind.CIRCLE,
					GameData.COLORS[key].hex, "", null)
		"animal":
			c.configure(key, Choice.Kind.IMAGE, Color.WHITE,
				GameData.ANIMALS[key].tr, _safe_load_texture(GameData.ANIMALS[key].img),
				GameData.ANIMALS[key].get("emoji", ""))
		"fruit":
			c.configure(key, Choice.Kind.IMAGE, Color.WHITE,
				GameData.FRUITS[key].tr, _safe_load_texture(GameData.FRUITS[key].img),
				GameData.FRUITS[key].get("emoji", ""))
	return c


func _safe_load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	Log.warn("LevelScene", "Görsel bulunamadı, placeholder kullanılıyor: %s" % path)
	return null


func _on_choice_chose(key: String) -> void:
	LevelManager.submit_answer(key)


func _on_answer_evaluated(is_correct: bool, _level: Dictionary, chosen_key: String) -> void:
	if is_correct:
		_play_correct_fx()
		for c in _choice_nodes:
			c.disable_after_correct()
	else:
		for c in _choice_nodes:
			if c.key == chosen_key:
				c.play_wrong_animation()
				break


func _play_correct_fx() -> void:
	confetti.restart()
	confetti.emitting = true
	bubble_text.text = ["Harika!", "Süpersin!", "Yeni Seviye!"].pick_random()
	bubble_text.visible = true
	bubble_text.modulate.a = 0.0
	bubble_text.scale = Vector2(0.5, 0.5)
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(bubble_text, "modulate:a", 1.0, 0.2)
	t.parallel().tween_property(bubble_text, "scale", Vector2(1.2, 1.2), 0.4)
	t.tween_property(bubble_text, "scale", Vector2(1.0, 1.0), 0.2)
	t.tween_interval(0.6)
	t.tween_property(bubble_text, "modulate:a", 0.0, 0.3)
