class_name Ground
extends Node2D
## 无限地面：按相机位置绘制底色与网格，深浅背景可切换（设计文档 4.1 / 9.4）。

var dark := false
var arena: Arena


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var cam: Vector2 = arena.camera.position if arena != null and arena.camera != null else Vector2.ZERO
	var bg := Color(0.15, 0.16, 0.18) if not dark else Color(0.05, 0.05, 0.07)
	draw_rect(Rect2(cam - Vector2(2200.0, 2200.0), Vector2(4400.0, 4400.0)), bg)

	var line := Color(1, 1, 1, 0.04) if not dark else Color(1, 1, 1, 0.07)
	var step := 64.0
	var from: Vector2 = (cam - Vector2(1400.0, 900.0)).snapped(Vector2(step, step))
	var to: Vector2 = cam + Vector2(1400.0, 900.0)
	var x := from.x
	while x <= to.x:
		draw_line(Vector2(x, from.y), Vector2(x, to.y), line)
		x += step
	var y := from.y
	while y <= to.y:
		draw_line(Vector2(from.x, y), Vector2(to.x, y), line)
		y += step
