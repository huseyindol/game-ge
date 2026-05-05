extends Node2D
## GameOverScene — 5 can bittiğinde gösterilir. "Tekrar Dene" başa sarar.

@onready var retry_button: Button = $RetryButton


func _ready() -> void:
	retry_button.pressed.connect(_on_retry)


func _on_retry() -> void:
	# Analytics bilerek korunur — ebeveyn ne kadar yanlış yapıldığını görür.
	LevelManager.start_new_game(false)
