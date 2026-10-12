class_name FireEgg
extends Node2D
## 火蛋弹体：数据持有 + 自绘；移动、终点结算（命中/撞墙/到期→燃烧区域）由 FireEggManager 驱动。
## 慢速大目标：蛋体沿飞行方向拉长，轮廓翻卷弱化，强调"投掷物"而非"炮弹"。

const TRAIL_LIFE := 0.22

var attack_id := -1
var rule: FireEggRule     # 发射时快照
var visual: VfxProfile
var dir := Vector2.RIGHT
var age := 0.0
var dead := false
var trail_pos: Array[Vector2] = []
var trail_age: Array[float] = []


func _ready() -> void:
	z_index = 20
	GameArt.apply_world_material(self)


func record_trail() -> void:
	trail_pos.append(position)
	trail_age.append(age)
	while trail_age.size() > 0 and age - trail_age[0] > TRAIL_LIFE:
		trail_age.remove_at(0)
		trail_pos.remove_at(0)


func _draw() -> void:
	if dead:
		return
	var radius := visual.body_radius * 1.2 if visual != null else rule.hit_radius
	var brightness := visual.brightness if visual != null else 1.0
	var n := trail_pos.size()
	for i in range(0, n, 4):
		var k := float(i + 1) / float(n)
		var side := 8.0 * k + 3.0
		draw_texture_rect(GameArt.fire(3), Rect2(trail_pos[i] - position - Vector2.ONE * side * 0.5,
				Vector2.ONE * side), false, Color(brightness, brightness, brightness, 0.28 * k))
	var pulse := 1.0 + 0.06 * sin(age * 9.0)
	draw_set_transform(Vector2.ZERO, dir.angle(), Vector2(pulse, pulse))
	var size := Vector2(radius * 3.4, radius * 2.7)
	draw_texture_rect(GameArt.fire(1), Rect2(Vector2(-size.x * 0.74, -size.y * 0.5), size),
			false, Color(brightness, brightness, brightness))
	draw_set_transform(Vector2.ZERO, age * 1.5, Vector2.ONE)
	draw_texture_rect(GameArt.fire(3), Rect2(-radius, -radius, radius * 2.0, radius * 2.0),
			false, Color(brightness, brightness, brightness, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
