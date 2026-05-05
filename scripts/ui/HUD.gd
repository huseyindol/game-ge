extends CanvasLayer
class_name HUD
## HUD — Üst panel: Kalpler + soru etiketi + ses çal butonu.
##
## "Süre veya sayaç GÖSTERİLMEZ" kuralı: bu node'ta hiçbir Timer label yoktur.

@onready var hearts_container: HBoxContainer = $Top/TopBar/HeartsContainer
@onready var prompt_label: Label = $Top/TopBar/PromptBox/PromptLabel
@onready var play_sound_button: Button = $Top/TopBar/PromptBox/PlaySoundButton

const HEART_FULL := "♥"
const HEART_EMPTY := "♡"
var _heart_labels: Array[Label] = []


func _ready() -> void:
	_build_hearts()
	LevelManager.lives_changed.connect(_on_lives_changed)
	LevelManager.level_started.connect(_on_level_started)
	play_sound_button.pressed.connect(_on_play_sound_pressed)
	_on_lives_changed(LevelManager.lives)


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
