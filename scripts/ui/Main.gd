extends Node2D
## Main — Açılış ekranı. "Başla" butonuna basınca yeni oyun başlar.

@onready var start_button: Button = $Center/StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start)


func _on_start() -> void:
	LevelManager.start_new_game(true)
