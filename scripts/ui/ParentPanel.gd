extends Control
class_name ParentPanel
## ParentPanel — Ebeveyn istatistik paneli.
##
## WinScene'deki ikon tıklanınca açılır. Verileri LevelManager.get_parent_summary()
## proxy'si üzerinden alır (UI hiçbir zaman AnalyticsManager ile doğrudan konuşmaz).

const CLR_TITLE := Color(0.36, 0.11, 0.58, 1)
const CLR_LABEL := Color(0.29, 0.34, 0.42, 1)
const CLR_VALUE := Color(0.43, 0.2, 0.78, 1)

@onready var content: VBoxContainer = $Center/CardWrap/Stack/Shell/VBox/Content
@onready var close_button: Button = $Center/CardWrap/Stack/Shell/VBox/FooterBar/CloseButton
@onready var popup_stack: Control = $Center/CardWrap/Stack
@onready var backdrop: ColorRect = $Backdrop


func _ready() -> void:
	visible = false
	visibility_changed.connect(_on_visibility_changed)
	close_button.pressed.connect(hide)
	backdrop.gui_input.connect(_on_backdrop_gui)


func _on_visibility_changed() -> void:
	if not visible:
		popup_stack.scale = Vector2.ONE
		popup_stack.pivot_offset = Vector2.ZERO


func _on_backdrop_gui(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			hide()


func open() -> void:
	_render()
	visible = true
	_play_open_popup()


func _play_open_popup() -> void:
	popup_stack.scale = Vector2(0.84, 0.84)
	await get_tree().process_frame
	popup_stack.pivot_offset = popup_stack.size * 0.5
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(popup_stack, "scale", Vector2.ONE, 0.4)


func _render() -> void:
	for c in content.get_children():
		c.queue_free()

	var s := LevelManager.get_parent_summary()
	_add_title("Ebeveyn Paneli")
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
	l.add_theme_font_size_override("font_size", 34)
	l.add_theme_color_override("font_color", CLR_TITLE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(l)
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 4)
	line.color = Color(0.62, 0.45, 0.92, 0.45)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(line)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 8)
	content.add_child(pad)


func _add_row(label: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 23)
	lbl.add_theme_color_override("font_color", CLR_LABEL)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 23)
	val.add_theme_color_override("font_color", CLR_VALUE)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val)
	content.add_child(row)