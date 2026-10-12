class_name DebugDraw
extends Node2D
## 开发者辅助显示：碰撞半径/拾取范围，仅试验模式开启（设计文档 9.4）。
## PROCESS_MODE_ALWAYS：世界暂停时也能检视。

var arena: Arena
var show_collisions := false


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not show_collisions or arena == null or arena.player == null:
		return
	draw_arc(arena.player.position, arena.player.radius, 0.0, TAU, 32, Color(0.3, 0.8, 1.0, 0.7), 1.5)
	draw_arc(arena.player.position, arena.player.pickup_radius, 0.0, TAU, 48, Color(0.3, 1.0, 0.5, 0.25), 1.0)
	for e in arena.enemies:
		if e.state == GameEnums.EnemyState.ALIVE:
			draw_arc(e.position, e.radius, 0.0, TAU, 24, Color(1.0, 0.9, 0.3, 0.7), 1.0)
	for b in arena.projectiles.balls:
		if not b.dead:
			draw_arc(b.position, b.rule.hit_radius, 0.0, TAU, 24, Color(1.0, 0.4, 0.4, 0.9), 1.0)
	for egg in arena.fire_eggs.eggs:
		draw_arc(egg.position, egg.rule.hit_radius, 0.0, TAU, 24, Color(1.0, 0.6, 0.2, 0.9), 1.0)
	for pool in arena.fire_eggs.pools:
		draw_arc(pool.position, pool.rule.pool_radius, 0.0, TAU, 40, Color(1.0, 0.6, 0.2, 0.8), 1.0)
