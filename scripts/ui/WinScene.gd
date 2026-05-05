extends Node2D
## WinScene — Final ekranı.
## Konfeti + "Tebrikler Kazandın!" bubble + sağ alt Ebeveyn ikonu.

@onready var confetti: CPUParticles2D = $Confetti
@onready var title: Label = $Title
@onready var parent_button: Button = $ParentIcon
@onready var parent_panel: ParentPanel = $ParentPanel
@onready var play_again: Button = $PlayAgain


func _ready() -> void:
	confetti.emitting = true
	AudioManager.play_sfx("win")
	_animate_title()
	parent_button.pressed.connect(_on_parent_pressed)
	play_again.pressed.connect(_on_play_again_pressed)


func _animate_title() -> void:
	title.text = "🎉 Tebrikler Kazandın! 🎉"
	title.scale = Vector2(0.4, 0.4)
	title.modulate.a = 0.0
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(title, "modulate:a", 1.0, 0.4)
	t.parallel().tween_property(title, "scale", Vector2(1.2, 1.2), 0.6)
	t.tween_property(title, "scale", Vector2(1.0, 1.0), 0.2)
	t.set_loops()
	t.tween_property(title, "scale", Vector2(1.05, 1.05), 0.6)
	t.tween_property(title, "scale", Vector2(1.0, 1.0), 0.6)


func _on_parent_pressed() -> void:
	parent_panel.open()


func _on_play_again_pressed() -> void:
	LevelManager.start_new_game(false)
