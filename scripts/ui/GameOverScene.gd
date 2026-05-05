extends Node2D
## GameOverScene — 5 can bittiğinde gösterilir. "Tekrar Dene" başa sarar.

@onready var background: ColorRect = $Background
@onready var retry_button: Button = $UI/UIRoot/RetryButton


func _ready() -> void:
	retry_button.pressed.connect(_on_retry)
	get_viewport().size_changed.connect(_fit_background)
	_fit_background()


func _fit_background() -> void:
	var s := get_viewport().get_visible_rect().size
	background.offset_left = 0.0
	background.offset_top = 0.0
	background.offset_right = s.x
	background.offset_bottom = s.y


func _on_retry() -> void:
	# Analytics bilerek korunur — ebeveyn ne kadar yanlış yapıldığını görür.
	LevelManager.start_new_game(false)
