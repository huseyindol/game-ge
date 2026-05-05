extends Button
class_name Choice
## Tek bir seçenek butonu (renkli daire, renk yazısı, hayvan/meyve görseli).

signal chose(key: String)

enum Kind { CIRCLE, TEXT, IMAGE }

const FONT_PATH := "res://fonts/Sigmar-Regular.ttf"
const BTN_SIZE := 200.0

var key: String = ""
var kind: Kind = Kind.CIRCLE
var color: Color = Color.WHITE
var label_text: String = ""
var texture: Texture2D = null
var emoji: String = ""

var _is_disabled: bool = false
var _configured: bool = false

const SHAKE_PIXELS := 14.0
const SHAKE_DURATION := 0.35


func configure(p_key: String, p_kind: Kind, p_color: Color,
		p_label: String, p_texture: Texture2D, p_emoji: String = "") -> void:
	key = p_key
	kind = p_kind
	color = p_color
	label_text = p_label
	texture = p_texture
	emoji = p_emoji
	_configured = true
	_apply_visuals()


func _ready() -> void:
	custom_minimum_size = Vector2(BTN_SIZE, BTN_SIZE)
	pressed.connect(_on_pressed)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not _configured:
		_apply_visuals()


func _apply_visuals() -> void:
	for c in get_children():
		c.queue_free()
	match kind:
		Kind.CIRCLE: _build_circle()
		Kind.TEXT:   _build_text()
		Kind.IMAGE:  _build_image()


# ── CIRCLE ────────────────────────────────────────────────────────────
func _build_circle() -> void:
	flat = false
	text = ""
	var sb := _make_circle_stylebox(color)
	add_theme_stylebox_override("normal", sb)
	add_theme_stylebox_override("hover", sb)
	add_theme_stylebox_override("pressed", sb)
	add_theme_stylebox_override("disabled", sb)


func _make_circle_stylebox(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.corner_radius_top_left = 999
	sb.corner_radius_top_right = 999
	sb.corner_radius_bottom_left = 999
	sb.corner_radius_bottom_right = 999
	sb.border_width_top = 5
	sb.border_width_bottom = 5
	sb.border_width_left = 5
	sb.border_width_right = 5
	sb.border_color = c.darkened(0.22)
	return sb


# ── TEXT ──────────────────────────────────────────────────────────────
func _build_text() -> void:
	flat = false
	text = ""
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.corner_radius_top_left = 24
	sb.corner_radius_top_right = 24
	sb.corner_radius_bottom_left = 24
	sb.corner_radius_bottom_right = 24
	sb.border_width_top = 6
	sb.border_width_bottom = 6
	sb.border_width_left = 6
	sb.border_width_right = 6
	sb.border_color = color
	add_theme_stylebox_override("normal", sb)
	add_theme_stylebox_override("hover", sb)
	add_theme_stylebox_override("pressed", sb)
	add_theme_stylebox_override("disabled", sb)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", color.darkened(0.1))
	lbl.add_theme_font_size_override("font_size", 52)
	var font := _load_font()
	if font:
		lbl.add_theme_font_override("font", font)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	lbl.anchor_left = 0.0; lbl.anchor_right = 1.0
	lbl.anchor_top = 0.0;  lbl.anchor_bottom = 1.0
	lbl.offset_left = 6; lbl.offset_right = -6
	lbl.offset_top = 6;  lbl.offset_bottom = -6
	add_child(lbl)
	call_deferred("_deferred_fit_text_label", lbl, label_text)


# ── IMAGE / EMOJI ─────────────────────────────────────────────────────
func _build_image() -> void:
	flat = false
	text = ""

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.9)
	sb.corner_radius_top_left = 24
	sb.corner_radius_top_right = 24
	sb.corner_radius_bottom_left = 24
	sb.corner_radius_bottom_right = 24
	sb.border_width_top = 4
	sb.border_width_bottom = 4
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_color = Color(0.85, 0.85, 0.85, 1)
	add_theme_stylebox_override("normal", sb)
	add_theme_stylebox_override("hover", sb)
	add_theme_stylebox_override("pressed", sb)
	add_theme_stylebox_override("disabled", sb)

	if texture != null:
		var img := TextureRect.new()
		img.texture = texture
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.anchor_left = 0.0; img.anchor_right = 1.0
		img.anchor_top = 0.0;  img.anchor_bottom = 1.0
		img.offset_bottom = -44
		add_child(img)
	elif not emoji.is_empty():
		var emo := Label.new()
		emo.text = emoji
		emo.add_theme_font_size_override("font_size", 80)
		emo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		emo.anchor_left = 0.0; emo.anchor_right = 1.0
		emo.anchor_top = 0.0;  emo.anchor_bottom = 1.0
		emo.offset_bottom = -44
		add_child(emo)

	var caption := Label.new()
	caption.text = label_text
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_color", Color(0.25, 0.1, 0.45, 1))
	var font := _load_font()
	if font:
		caption.add_theme_font_override("font", font)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.anchor_left = 0.0; caption.anchor_right = 1.0
	caption.anchor_top = 1.0;  caption.anchor_bottom = 1.0
	caption.offset_top = -42; caption.offset_bottom = -4
	caption.clip_text = true
	add_child(caption)
	call_deferred("_deferred_fit_caption", caption, label_text)


func _load_font() -> FontFile:
	if ResourceLoader.exists(FONT_PATH):
		return load(FONT_PATH) as FontFile
	return null


func _deferred_fit_text_label(lbl: Label, line: String) -> void:
	var max_w := maxf(BTN_SIZE - 20.0, 40.0)
	_fit_label_line_to_width(lbl, line, 52, 20, max_w)


func _deferred_fit_caption(lbl: Label, line: String) -> void:
	var max_w := maxf(BTN_SIZE - 16.0, 40.0)
	_fit_label_line_to_width(lbl, line, 20, 13, max_w)


func _fit_label_line_to_width(lbl: Label, line: String, max_fs: int, min_fs: int, max_w: float) -> void:
	if line.is_empty():
		return
	var font := lbl.get_theme_font("font")
	if font == null:
		lbl.add_theme_font_size_override("font_size", max_fs)
		return
	for sz in range(max_fs, min_fs - 1, -1):
		var w := float(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x)
		if w <= max_w:
			lbl.add_theme_font_size_override("font_size", sz)
			return
	lbl.add_theme_font_size_override("font_size", min_fs)


# ── ETKİLEŞİM ────────────────────────────────────────────────────────

func _on_pressed() -> void:
	if _is_disabled:
		return
	chose.emit(key)


func play_wrong_animation() -> void:
	var orig_pos := position
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in 4:
		t.tween_property(self, "position:x", orig_pos.x - SHAKE_PIXELS, SHAKE_DURATION / 8.0)
		t.tween_property(self, "position:x", orig_pos.x + SHAKE_PIXELS, SHAKE_DURATION / 8.0)
	t.tween_property(self, "position", orig_pos, 0.05)
	t.parallel().tween_property(self, "modulate:a", 0.3, SHAKE_DURATION)


func disable_after_correct() -> void:
	_is_disabled = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_ARROW
