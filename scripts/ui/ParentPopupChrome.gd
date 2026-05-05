extends Control
## Ebeveyn kartının arkasında çizilir: dolu zemin hissi için hafif vurgulu alt dalga çizgisi.

@export var wave_color := Color(0.5, 0.32, 0.82, 0.85)
@export var wave_amp := 6.0


func _draw() -> void:
	if size.x < 40.0 or size.y < 40.0:
		return

	var steps := clampi(int(size.x / 12.0), 24, 64)
	var left := 18.0
	var right := size.x - 18.0

	var pts_b := PackedVector2Array()
	var y_b := size.y - 22.0
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := lerpf(left, right, t)
		var wy := wave_amp * sin(t * PI * 5.0 + 0.4)
		pts_b.append(Vector2(x, y_b + wy))
	draw_polyline(pts_b, wave_color, 4.5)

	var y_t := 18.0
	var pts_t := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := lerpf(left, right, t)
		var wy := wave_amp * sin(t * PI * 5.0 + PI + 0.4)
		pts_t.append(Vector2(x, y_t + wy))
	var wave_top := Color(wave_color.r, wave_color.g, wave_color.b, wave_color.a * 0.75)
	draw_polyline(pts_t, wave_top, 3.5)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
