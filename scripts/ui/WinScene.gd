extends Node2D
## WinScene — Final ekranı.
## Konfeti + iki satır tebrik metni + ebeveyn bilgi yazısı + sağ alt ebeveyn paneli ikonu.

@onready var confetti: CPUParticles2D = $Confetti
@onready var title: Label = $UI/UIRoot/Title
@onready var parent_button: Button = $UI/UIRoot/ParentIcon
@onready var parent_panel: ParentPanel = $UI/ParentPanel
@onready var play_again: Button = $UI/UIRoot/PlayAgain


func _ready() -> void:
	confetti.emitting = true
	AudioManager.play_sfx("win")
	_animate_title()
	parent_button.pressed.connect(_on_parent_pressed)
	play_again.pressed.connect(_on_play_again_pressed)


func _animate_title() -> void:
	# Tek satır + büyük scale editördekinden farklı taşır; iki satır + scale yok.
	title.text = "🎉 Tebrikler\nKazandın! 🎉"
	title.scale = Vector2.ONE
	title.modulate.a = 0.0
	var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(title, "modulate:a", 1.0, 0.55)
	await t.finished
	var pulse := create_tween().set_loops()
	pulse.tween_property(title, "modulate:a", 0.88, 0.55).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(title, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)


func _on_parent_pressed() -> void:
	parent_panel.open()


func _on_play_again_pressed() -> void:
	LevelManager.start_new_game(false)
