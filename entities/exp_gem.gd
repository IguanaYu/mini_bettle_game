class_name ExpGem
extends Node2D
## 经验物：静止 → 进入拾取半径后吸取 → 接触入账一次（设计文档 7.1）。

var value := 5
var attracted := false
var attract_speed := 420.0
var player: Player


func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Palette.c(Color(0.35, 0.75, 1.0)))
	draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 16, Palette.c(Color(0.75, 0.95, 1.0, 0.8)), 1.5)
