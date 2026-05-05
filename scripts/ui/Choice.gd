extends Button
class_name Choice
## Tek bir seçenek butonu (renkli daire, renk yazısı, hayvan/meyve görseli).
##
## LevelScene tarafından runtime'da configure() çağrısıyla doldurulur.
## "Çoklu yanlışta sadece 1 can" kuralı LevelManager'da çözülür — bu sınıf
## yalnızca görsel davranıştan (shake, fade) sorumludur.

signal chose(key: String)

enum Kind { CIRCLE, TEXT, IMAGE }

@export var key: String = ""
@export var kind: Kind = Kind.CIRCLE
@export var color: Color = Color.WHITE
@export var label_text: String = ""
@export var texture: Texture2D = null

var _is_disabled_after_correct: bool = false
const SHAKE_PIXELS := 12.0
const SHAKE_DURATION := 0.35


func configure(p_key: String, p_kind: Kind, p_color: Color,
		p_label: String, p_texture: Texture2D) -> void:
	key = p_key
	kind = p_kind
	color = p_color
	label_text = p_label
	texture = p_texture
	_apply_visuals()


func _ready() -> void:
	custom_minimum_size = Vector2(160, 160)
	pressed.connect(_on_pressed)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_visuals()


func _apply_visuals() -> void:
	# Çocuk node'ları temizle (yeniden configure için).
	for c in get_children():
		c.queue_free()

	match kind:
		Kind.CIRCLE:
			_build_circle()
		Kind.TEXT:
			_build_text()
		Kind.IMAGE:
			_build_image()


func _build_circle() -> void:
	flat = false
	text = ""
	# Yuvarlak StyleBox — köşe yarıçapı yüksek tutulunca daire elde edilir.
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 999
	sb.corner_radius_top_right = 999
	sb.corner_radius_bottom_left = 999
	sb.corner_radius_bottom_right = 999
	sb.border_width_top = 4
	sb.border_width_bottom = 4
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_color = color.darkened(0.2)
	add_theme_stylebox_override("normal", sb)
	add_theme_stylebox_override("hover", sb)
	add_theme_stylebox_override("pressed", sb)


func _build_text() -> void:
	flat = true
	text = ""
	var lbl := Label.new()
	lbl.name = "TextLabel"
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 48)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(lbl)


func _build_image() -> void:
	flat = true
	text = ""
	if texture != null:
		var img := TextureRect.new()
		img.name = "Img"
		img.texture = texture
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(img)
	# Görsel altına Türkçe ad da yazalım (öğretici).
	var caption := Label.new()
	caption.text = label_text
	caption.add_theme_font_size_override("font_size", 24)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caption.position.y = -28
	add_child(caption)


# =====================================================================
#  ETKİLEŞİM — shake / fade
# =====================================================================

func _on_pressed() -> void:
	if _is_disabled_after_correct:
		return
	chose.emit(key)


## LevelScene yanlış cevap olduğunda çağırır.
func play_wrong_animation() -> void:
	var orig_pos := position
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Shake
	for i in 4:
		t.tween_property(self, "position:x", orig_pos.x - SHAKE_PIXELS, SHAKE_DURATION / 8.0)
		t.tween_property(self, "position:x", orig_pos.x + SHAKE_PIXELS, SHAKE_DURATION / 8.0)
	t.tween_property(self, "position", orig_pos, 0.05)
	# Fade
	t.parallel().tween_property(self, "modulate:a", 0.25, SHAKE_DURATION)


## LevelScene doğru cevap olduğunda diğer butonları kilitler.
func disable_after_correct() -> void:
	_is_disabled_after_correct = true
	disabled = true
