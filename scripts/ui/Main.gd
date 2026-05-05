extends Node2D
## Main — Açılış ekranı. "Başla" butonuna basınca yeni oyun başlar.

@onready var background: ColorRect = $Background
@onready var start_button: Button = $UI/UIRoot/StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start)
	get_viewport().size_changed.connect(_fit_background)
	_fit_background()


func _fit_background() -> void:
	var s := get_viewport().get_visible_rect().size
	background.offset_left = 0.0
	background.offset_top = 0.0
	background.offset_right = s.x
	background.offset_bottom = s.y


func _on_start() -> void:
	LevelManager.start_new_game(true)
