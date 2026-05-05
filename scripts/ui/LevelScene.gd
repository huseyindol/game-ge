extends Node2D
## LevelScene — 24 seviyenin tümünü çalıştıran tek sahne.
##
## Dikey/yatay: Üstte kalpler + ses + tam genişlikte ortalanmış hedef yazısı;
## altta seçenekler ortada. 4/6 seçenek için sütun sayısı ekran genişliğine göre ayarlanır.

@onready var background: ColorRect = $Background
@onready var choices_container: GridContainer = %ChoicesContainer
@onready var confetti: CPUParticles2D = $FXLayer/Confetti
@onready var bubble_text: Label = $FXLayer/BubbleText
@onready var main_layout: MarginContainer = $HUD/MainLayout
@onready var root_vbox: VBoxContainer = $HUD/MainLayout/RootVBox
@onready var top_block: VBoxContainer = $HUD/MainLayout/RootVBox/TopBlock
@onready var choices_center: CenterContainer = $HUD/MainLayout/RootVBox/ChoicesCenter

const CHOICE_SEP := 24.0

var _choice_nodes: Array[Choice] = []
var _last_choice_count: int = 0


func _ready() -> void:
	_purge_legacy_landscape_hbox()
	LevelManager.level_started.connect(_on_level_started)
	LevelManager.answer_evaluated.connect(_on_answer_evaluated)
	bubble_text.visible = false
	confetti.emitting = false

	get_viewport().size_changed.connect(_on_viewport_changed)
	_on_viewport_changed()

	LevelManager.enter_current_level()


func _purge_legacy_landscape_hbox() -> void:
	var h := main_layout.get_node_or_null("RootHBox")
	if h != null:
		h.queue_free()


func _on_viewport_changed() -> void:
	_sync_viewport_nodes()
	_everything_stays_in_main_column()
	call_deferred("_deferred_refresh_choice_grid")
	call_deferred("_deferred_refit_bubble_font")


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

	var band := clampf(sz.y * 0.2, 120.0, 220.0)
	# BubbleText: anchor_top/bottom = 0.5 → dikey orta bant (offset_top/bottom merkeze göre).
	# anchor_left/right = 0..1 → tam genişlik için offset_left/right = 0 (offset_right = genişlik EKLEME).
	bubble_text.offset_left = 0.0
	bubble_text.offset_right = 0.0
	bubble_text.offset_top = -band * 0.5
	bubble_text.offset_bottom = band * 0.5
	bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _everything_stays_in_main_column() -> void:
	if top_block.get_parent() != root_vbox:
		top_block.reparent(root_vbox)
	if choices_center.get_parent() != root_vbox:
		choices_center.reparent(root_vbox)

	root_vbox.visible = true
	top_block.custom_minimum_size = Vector2.ZERO
	top_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_block.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	choices_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices_center.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _deferred_refit_bubble_font() -> void:
	var sz := get_viewport().get_visible_rect().size
	var m := minf(sz.x, sz.y)
	var fs := clampi(int(m * 0.09), 38, 108)
	bubble_text.add_theme_font_size_override("font_size", fs)


func _columns_for_count(n: int, avail_w: float) -> int:
	if n <= 0:
		return 2
	var cell := Choice.BTN_SIZE
	var max_cols := 1
	for k in range(1, n + 1):
		var row_w := float(k) * cell + float(k - 1) * CHOICE_SEP
		if row_w <= avail_w * 0.96:
			max_cols = k
	if n == 4:
		return 4 if max_cols >= 4 else 2
	if n == 6:
		if max_cols >= 6:
			return 6
		if max_cols >= 3:
			return 3
		return maxi(2, mini(max_cols, n))
	return clampi(max_cols, 1, n)


func _deferred_refresh_choice_grid() -> void:
	if _last_choice_count <= 0:
		choices_container.scale = Vector2.ONE
		choices_container.pivot_offset = Vector2.ZERO
		return

	var aw := choices_center.size.x
	var ah := choices_center.size.y
	var vsz := get_viewport().get_visible_rect().size
	if aw < 48.0:
		aw = maxf(200.0, vsz.x - 80.0)
	if ah < 48.0:
		ah = maxf(200.0, vsz.y * 0.42)

	var cols := _columns_for_count(_last_choice_count, aw)
	choices_container.columns = cols
	await get_tree().process_frame

	var c := choices_container.columns
	var rows := int(ceil(float(_last_choice_count) / float(c)))
	var gw := float(c) * Choice.BTN_SIZE + float(maxi(0, c - 1)) * CHOICE_SEP
	var gh := float(rows) * Choice.BTN_SIZE + float(maxi(0, rows - 1)) * CHOICE_SEP
	var sx := aw / gw if gw > 0.001 else 1.0
	var sy := ah / gh if gh > 0.001 else 1.0
	var sc := minf(minf(sx, sy), 1.0)
	choices_container.scale = Vector2(sc, sc)
	choices_container.pivot_offset = choices_container.size * 0.5


func _on_level_started(level: Dictionary, choice_keys: Array) -> void:
	_clear_choices()
	_last_choice_count = choice_keys.size()

	for key in choice_keys:
		var ch := _build_choice_for(level, key)
		choices_container.add_child(ch)
		ch.chose.connect(_on_choice_chose)
		_choice_nodes.append(ch)

	AudioManager.speak_word(GameData.get_display_name(level))
	call_deferred("_deferred_refresh_choice_grid")


func _clear_choices() -> void:
	for c in _choice_nodes:
		c.queue_free()
	_choice_nodes.clear()
	_last_choice_count = 0
	choices_container.scale = Vector2.ONE
	choices_container.pivot_offset = Vector2.ZERO


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
	_deferred_refit_bubble_font()
	bubble_text.visible = true
	bubble_text.modulate.a = 0.0
	bubble_text.scale = Vector2(0.5, 0.5)
	await get_tree().process_frame
	bubble_text.pivot_offset = bubble_text.size * 0.5
	var vmax := 1.12 if minf(
		get_viewport().get_visible_rect().size.x,
		get_viewport().get_visible_rect().size.y,
	) > 560.0 else 1.06
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(bubble_text, "modulate:a", 1.0, 0.2)
	t.parallel().tween_property(bubble_text, "scale", Vector2(vmax, vmax), 0.4)
	t.tween_property(bubble_text, "scale", Vector2.ONE, 0.2)
	t.tween_interval(0.6)
	t.tween_property(bubble_text, "modulate:a", 0.0, 0.3)
