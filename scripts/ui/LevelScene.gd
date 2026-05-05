extends Node2D
## LevelScene — 24 seviyenin tümünü çalıştıran tek sahne.
##
## LevelManager state'i tutar; biz onu DİNLER ve görselleştiririz.

@onready var choices_container: GridContainer = $ChoicesContainer
@onready var confetti: CPUParticles2D = $FXLayer/Confetti
@onready var bubble_text: Label = $FXLayer/BubbleText

const CHOICE_GRID_4 := 2
const CHOICE_GRID_6 := 3

var _choice_nodes: Array[Choice] = []


func _ready() -> void:
	# Sinyalleri bağla.
	LevelManager.level_started.connect(_on_level_started)
	LevelManager.answer_evaluated.connect(_on_answer_evaluated)
	bubble_text.visible = false
	confetti.emitting = false

	# LevelManager bu sahneye girildiğinde mevcut seviyeyi yükler.
	LevelManager.enter_current_level()


func _on_level_started(level: Dictionary, choice_keys: Array) -> void:
	_clear_choices()
	choices_container.columns = CHOICE_GRID_6 if level.choices == 6 else CHOICE_GRID_4

	for key in choice_keys:
		var c := _build_choice_for(level, key)
		choices_container.add_child(c)
		c.chose.connect(_on_choice_chose)
		_choice_nodes.append(c)


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
			# Yarısı daire, yarısı yazı.
			var as_text := randi() % 2 == 0
			if as_text:
				c.configure(key, Choice.Kind.TEXT,
					GameData.COLORS[key].hex, GameData.COLORS[key].tr, null)
			else:
				c.configure(key, Choice.Kind.CIRCLE,
					GameData.COLORS[key].hex, "", null)
		"animal":
			c.configure(key, Choice.Kind.IMAGE, Color.WHITE,
				GameData.ANIMALS[key].tr, _safe_load_texture(GameData.ANIMALS[key].img))
		"fruit":
			c.configure(key, Choice.Kind.IMAGE, Color.WHITE,
				GameData.FRUITS[key].tr, _safe_load_texture(GameData.FRUITS[key].img))
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
