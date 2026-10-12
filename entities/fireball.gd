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


func _ready() -> void:
	z_index = 20
	GameArt.apply_world_material(self)


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
	var out: Array[Vector2] = []
	out.assign(trail_pos)
	return out


func _draw() -> void:
	if visual == null or dead:
		return
	var b := clampf(visual.brightness, 0.2, 3.0)
	var n := trail_pos.size()
	for i in range(0, n, 3):
		var k := float(i + 1) / float(n)
		var side := visual.body_radius * (0.5 + k)
		var offset := Vector2(-dir.y, dir.x) * sin(float(i) * 1.4 + age * 18.0) * visual.body_wobble
		draw_texture_rect(GameArt.fire(3), Rect2(trail_pos[i] - position + offset - Vector2.ONE * side * 0.5,
				Vector2.ONE * side), false, Color(b, b, b, 0.32 * k))
	var pulse := 1.0 + sin(age * 22.0) * 0.035
	var roll := sin(age * 27.0) * visual.body_wobble * 0.03
	draw_set_transform(Vector2.ZERO, dir.angle(), Vector2(pulse, 1.0 + roll))
	var size := Vector2(visual.body_radius * 4.8, visual.body_radius * 2.6)
	# The authored flame points right; its bright core sits at 78% of the trimmed width.
	draw_texture_rect(GameArt.fire(1), Rect2(Vector2(-size.x * 0.78, -size.y * 0.5), size),
			false, Color(b, b, b))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
