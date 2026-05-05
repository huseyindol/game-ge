extends CanvasLayer
class_name HUD
## HUD — Üst panel: Kalpler + soru etiketi + ses çal butonu.
##
## "Süre veya sayaç GÖSTERİLMEZ" kuralı: bu node'ta hiçbir Timer label yoktur.

@onready var hearts_container: HBoxContainer = $MainLayout/RootVBox/TopBlock/IconsRow/HeartsContainer
@onready var prompt_label: Label = $MainLayout/RootVBox/TopBlock/PromptLabel
@onready var play_sound_button: Button = $MainLayout/RootVBox/TopBlock/IconsRow/PlaySoundButton

const PROMPT_FONT_MAX := 76
const PROMPT_FONT_MIN := 24

const HEART_FULL := "♥"
const HEART_EMPTY := "♡"
var _heart_labels: Array[Label] = []


func _ready() -> void:
	_build_hearts()
	LevelManager.lives_changed.connect(_on_lives_changed)
	LevelManager.level_started.connect(_on_level_started)
	play_sound_button.pressed.connect(_on_play_sound_pressed)
	prompt_label.resized.connect(_on_prompt_resized)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_lives_changed(LevelManager.lives)


func _on_viewport_size_changed() -> void:
	if not prompt_label.text.is_empty():
		_fit_prompt_font.call_deferred()


func _build_hearts() -> void:
	for c in hearts_container.get_children():
		c.queue_free()
	_heart_labels.clear()
	for i in GameData.MAX_LIVES:
		var l := Label.new()
		l.text = HEART_FULL
		l.add_theme_font_size_override("font_size", 42)
		l.add_theme_color_override("font_color", Color("#EF476F"))
		hearts_container.add_child(l)
		_heart_labels.append(l)


func _on_lives_changed(remaining: int) -> void:
	for i in _heart_labels.size():
		_heart_labels[i].text = HEART_FULL if i < remaining else HEART_EMPTY


func _on_level_started(level: Dictionary, _choices: Array) -> void:
	prompt_label.text = GameData.get_display_name(level)
	prompt_label.add_theme_color_override("font_color", GameData.get_prompt_color(level))
	_fit_prompt_font.call_deferred()


func _on_prompt_resized() -> void:
	if prompt_label.text.is_empty():
		return
	_fit_prompt_font()


func _fit_prompt_font() -> void:
	var text := prompt_label.text
	if text.is_empty():
		return
	var font := prompt_label.get_theme_font("font")
	var max_w := float(prompt_label.size.x)
	if max_w < 80.0:
		max_w = 640.0
	if font == null:
		prompt_label.add_theme_font_size_override("font_size", PROMPT_FONT_MAX)
		return
	for sz in range(PROMPT_FONT_MAX, PROMPT_FONT_MIN - 1, -1):
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		if w <= max_w:
			prompt_label.add_theme_font_size_override("font_size", sz)
			return
	prompt_label.add_theme_font_size_override("font_size", PROMPT_FONT_MIN)


func _on_play_sound_pressed() -> void:
	var lv := LevelManager.get_current_level()
	if lv.is_empty():
		return
	# Hayvan/meyve seviyelerinde özel ses veya TTS; renklerde TTS.
	match lv.type:
		"animal":
			AudioManager.play_or_speak(GameData.ANIMALS[lv.target].sfx, GameData.ANIMALS[lv.target].tr)
		"fruit":
			AudioManager.play_or_speak(GameData.FRUITS[lv.target].sfx, GameData.FRUITS[lv.target].tr)
		_:
			AudioManager.speak_word(GameData.COLORS[lv.target].tr)
