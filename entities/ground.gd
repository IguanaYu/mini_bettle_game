class_name Ground
extends Node2D
## 封闭竞技场地面（Brotato 式）：固定大小的带墙场地，墙外为虚空，
## 网格只画在可行动区内。深浅背景可切换（原设计文档 4.1 的有限版）。

var dark := false
var arena: Arena


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var inner := Arena.arena_inner_rect()
	var outer := Rect2(-Arena.ARENA_HALF, Arena.ARENA_HALF * 2.0)

	# 墙外虚空：铺满可视余量，避免拉伸窗口后露底
	var void_c := Color(0.03, 0.03, 0.04) if not dark else Color(0.015, 0.015, 0.02)
	draw_rect(Rect2(-Vector2(2200, 2200), Vector2(4400, 4400)), void_c)

	# 可行动区地板
	var floor_c := Color(0.15, 0.16, 0.18) if not dark else Color(0.05, 0.05, 0.07)
	draw_rect(inner, floor_c)

	# 区内网格：64px，对齐内区左上角，线条止于墙
	var line := Color(1, 1, 1, 0.04) if not dark else Color(1, 1, 1, 0.07)
	var step := 64.0
	var x := inner.position.x
	while x <= inner.end.x:
		draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), line)
		x += step
	var y := inner.position.y
	while y <= inner.end.y:
		draw_line(Vector2(inner.position.x, y), Vector2(inner.end.x, y), line)
		y += step

	# 四面墙：外圈实体带（不覆盖地板与网格）+ 内沿亮线（墙=障碍的可读性）
	var wall_c := Color(0.27, 0.28, 0.33) if not dark else Color(0.10, 0.10, 0.13)
	var w := Arena.WALL
	draw_rect(Rect2(outer.position, Vector2(outer.size.x, w)), wall_c)                          # 上
	draw_rect(Rect2(Vector2(outer.position.x, inner.end.y), Vector2(outer.size.x, w)), wall_c)  # 下
	draw_rect(Rect2(outer.position.x, inner.position.y, w, inner.size.y), wall_c)               # 左
	draw_rect(Rect2(inner.end.x, inner.position.y, w, inner.size.y), wall_c)                    # 右

	var edge := Color(1, 1, 1, 0.22) if not dark else Color(1, 1, 1, 0.10)
	draw_rect(inner.grow(1.5), edge, false, 3.0)
	draw_rect(outer.grow(-1.5), Color(0, 0, 0, 0.35), false, 3.0)  # 墙外沿暗线
