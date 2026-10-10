class_name Fireball
extends Node2D
## 火球弹体：数据持有 + 自绘；移动与命中检测由 ProjectileManager 驱动（开发方案 5.3）。

var attack_id := -1
var rule: AttackRule     # 发射时快照：升级后旧弹体不受影响（开发方案 3.5）
var visual: VfxProfile   # 发射时快照：A/B 切换不影响已生成弹体（设计文档 9.3）
var dir := Vector2.RIGHT
var age := 0.0
var dead := false        # 命中或到期，等待移除
var pierced := 0
var hit_targets: Dictionary = {}  # pierce>0 时防同一目标重复命中
var trail_pos: Array[Vector2] = []
var trail_age: Array[float] = []


func record_trail() -> void:
	## 每帧记录轨迹点，按尾迹寿命裁剪（时间基准，与帧率无关）
	if visual == null:
		return
	trail_pos.append(position)
	trail_age.append(age)
	while trail_age.size() > 0 and age - trail_age[0] > visual.trail_lifetime:
		trail_age.remove_at(0)
		trail_pos.remove_at(0)


func trail_snapshot() -> Array[Vector2]:
	return trail_pos.duplicate()


func _draw() -> void:
	if visual == null:
		return
	var b := clampf(visual.brightness, 0.2, 3.0)
	# 尾迹：越旧的点越小越淡
	var n := trail_pos.size()
	for i in n:
		var k := float(i + 1) / float(n)
		draw_circle(trail_pos[i] - position, visual.body_radius * 0.55 * k,
				Palette.c(Color(1.0, 0.50, 0.15, 0.35 * k * b)))
	# B 版轮廓翻卷：两个反向偏移的副圆（设计文档 6.3）
	if visual.body_wobble > 0.0:
		var o := Vector2(dir.y, -dir.x) * sin(age * 24.0) * visual.body_wobble
		draw_circle(o, visual.body_radius * 0.9, Palette.c(Color(1.0, 0.45, 0.10, 0.9 * b)))
		draw_circle(-o * 0.7, visual.body_radius * 0.85, Palette.c(Color(1.0, 0.55, 0.15, 0.85 * b)))
	draw_circle(Vector2.ZERO, visual.body_radius, Palette.c(Color(1.0, 0.50, 0.12, b)))
	draw_circle(Vector2.ZERO, visual.body_radius * 0.5, Palette.c(Color(1.0, 0.85, 0.45, b)))
