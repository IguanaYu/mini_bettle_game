class_name ExpGem
extends Node2D
## 经验物：静止 → 进入拾取半径后吸取 → 接触入账一次（设计文档 7.1）。

var value := 5
var attracted := false
var attract_speed := 420.0
var player: Player
var visual_time := 0.0


func _ready() -> void:
	z_index = -4
	GameArt.apply_world_material(self)


func tick(delta: float) -> void:
	visual_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + sin(visual_time * 3.5 + position.x * 0.03) * 0.05
	var r := 5.5 * pulse
	draw_colored_polygon(PackedVector2Array([Vector2(0, -r - 2), Vector2(r, -1),
			Vector2(r * 0.8, r * 0.7), Vector2(0, r + 2), Vector2(-r, r * 0.4),
			Vector2(-r, -1)]), Palette.c(Color(0.1, 0.58, 0.83)))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -r - 2), Vector2(r, -1),
			Vector2(0, r + 2)]), Palette.c(Color(0.22, 0.78, 0.96)))
	draw_line(Vector2(0, -r - 1), Vector2(-r + 1, -1),
			Palette.c(Color(0.7, 0.95, 1.0)), 1.0, true)
