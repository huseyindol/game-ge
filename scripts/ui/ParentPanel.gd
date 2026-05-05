extends Control
class_name ParentPanel
## ParentPanel — Ebeveyn istatistik paneli.
##
## WinScene'deki ikon tıklanınca açılır. Verileri LevelManager.get_parent_summary()
## proxy'si üzerinden alır (UI hiçbir zaman AnalyticsManager ile doğrudan konuşmaz).

@onready var content: VBoxContainer = $Center/Background/Content
@onready var close_button: Button = $Center/Background/CloseButton


func _ready() -> void:
	visible = false
	close_button.pressed.connect(hide)


func open() -> void:
	_render()
	visible = true


func _render() -> void:
	for c in content.get_children():
		c.queue_free()

	var s := LevelManager.get_parent_summary()
	_add_title("📊 Ebeveyn Paneli")
	_add_row("Doğruluk Oranı",      "%%%.1f"   % s.accuracy_percent)
	_add_row("Yanlış Yapma Oranı",  "%%%.1f"   % s.wrong_percent)
	_add_row("Toplam Doğru",        "%d"       % s.total_correct)
	_add_row("Toplam Yanlış",       "%d"       % s.total_wrong)
	_add_row("Ortalama Tepki",      "%.2f sn"  % s.avg_response_sec)
	_add_row("En Uzun Doğru Seri",  "%d"       % s.longest_correct_streak)
	_add_row("En Uzun Yanlış Seri", "%d"       % s.longest_wrong_streak)
	_add_row("Oynanan Seviye",      "%d / %d"  % [s.levels_played, GameData.TOTAL_LEVELS])
	_add_row("Oturum Süresi",       "%.0f sn"  % s.session_duration_sec)


func _add_title(t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 32)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(l)
	content.add_child(HSeparator.new())


func _add_row(label: String, value: String) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.add_theme_font_size_override("font_size", 22)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 22)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(v)
	content.add_child(row)
