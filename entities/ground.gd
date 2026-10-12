class_name Ground
extends Node2D
## 石地竞技场；贴图镜像拼接，边界仍由 Arena 的同一矩形定义。

var dark := false:
	set(value):
		dark = value
		queue_redraw()
var arena: Arena


func _ready() -> void:
	z_index = -50
	GameArt.apply_world_material(self)


func _draw() -> void:
	var inner := Arena.arena_inner_rect()
	var outer := Rect2(-Arena.ARENA_HALF, Arena.ARENA_HALF * 2.0)

	draw_rect(Rect2(-2200, -2200, 4400, 4400), Color(0.035, 0.04, 0.04))
	_stone_surface(outer, 256.0, 1.05 if not dark else 0.48)
	_stone_surface(inner, 320.0, 0.82 if not dark else 0.32)
	# A restrained wall shadow gives the border height without obscuring the arena.
	var w := Arena.WALL
	draw_rect(Rect2(inner.position, Vector2(inner.size.x, 8)), Color(0, 0, 0, 0.20))
	draw_rect(Rect2(inner.position, Vector2(5, inner.size.y)), Color(0, 0, 0, 0.14))
	for x in range(-640, 641, 64):
		draw_line(Vector2(x, outer.position.y), Vector2(x, outer.position.y + w), Color(0, 0, 0, 0.3), 2.0)
		draw_line(Vector2(x, inner.end.y), Vector2(x, outer.end.y), Color(0, 0, 0, 0.3), 2.0)
	for y in range(-336, 337, 64):
		draw_line(Vector2(outer.position.x, y), Vector2(inner.position.x, y), Color(0, 0, 0, 0.3), 2.0)
		draw_line(Vector2(inner.end.x, y), Vector2(outer.end.x, y), Color(0, 0, 0, 0.3), 2.0)
	draw_rect(inner, Color(0.85, 0.85, 0.78, 0.22 if not dark else 0.12), false, 1.5)
	draw_rect(outer.grow(-1), Color(0, 0, 0, 0.5), false, 2.0)


func _stone_surface(bounds: Rect2, side: float, shade: float) -> void:
	var source_scale := Vector2(GameArt.FLOOR.get_size()) / side
	for row in int(ceil(bounds.size.y / side)):
		for col in int(ceil(bounds.size.x / side)):
			var tile := Rect2(bounds.position + Vector2(col, row) * side, Vector2.ONE * side)
			var clipped := tile.intersection(bounds)
			var origin := (clipped.position - tile.position) * source_scale
			var extent := clipped.size * source_scale
			var mirror := Vector2(-1 if col % 2 else 1, -1 if row % 2 else 1)
			if mirror.x < 0:
				origin.x = GameArt.FLOOR.get_width() - origin.x - extent.x
			if mirror.y < 0:
				origin.y = GameArt.FLOOR.get_height() - origin.y - extent.y
			var offset := clipped.position + clipped.size * (Vector2.ONE - mirror) * 0.5
			draw_set_transform(offset, 0.0, mirror)
			draw_texture_rect_region(GameArt.FLOOR, Rect2(Vector2.ZERO, clipped.size),
					Rect2(origin, extent), Color(shade, shade, shade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
