class_name FireEgg
extends Node2D
## 火蛋弹体：数据持有 + 自绘；移动、终点结算（命中/撞墙/到期→燃烧区域）由 FireEggManager 驱动。
## 慢速大目标：蛋体沿飞行方向拉长，轮廓翻卷弱化，强调"投掷物"而非"炮弹"。

const TRAIL_LIFE := 0.22

var attack_id := -1
var rule: FireEggRule     # 发射时快照
var dir := Vector2.RIGHT
var age := 0.0
var dead := false
var trail_pos: Array[Vector2] = []
var trail_age: Array[float] = []


func record_trail() -> void:
	trail_pos.append(position)
	trail_age.append(age)
	while trail_age.size() > 0 and age - trail_age[0] > TRAIL_LIFE:
		trail_age.remove_at(0)
		trail_pos.remove_at(0)


func _draw() -> void:
	# 尾迹：越旧的点越小越淡
	var n := trail_pos.size()
	for i in n:
		var k := float(i + 1) / float(n)
		draw_circle(trail_pos[i] - position, 6.0 * k,
				Palette.c(Color(1.0, 0.50, 0.15, 0.30 * k)))
	# 蛋体：沿飞行方向拉长的椭圆；轻微呼吸脉动
	var pulse := 1.0 + 0.06 * sin(age * 9.0)
	draw_set_transform(Vector2.ZERO, dir.angle(), Vector2(1.18 * pulse, 0.88 * pulse))
	draw_circle(Vector2.ZERO, rule.hit_radius, Palette.c(Color(1.0, 0.42, 0.10)))
	draw_circle(Vector2.ZERO, rule.hit_radius * 0.58, Palette.c(Color(1.0, 0.78, 0.38)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 高光与底部阴影点：让"蛋"有体积感
	draw_circle(Vector2(2.5, -2.5), 2.0, Palette.c(Color(1.0, 0.93, 0.72, 0.9)))
	draw_circle(Vector2(-3.0, 3.0), 1.6, Palette.c(Color(0.9, 0.30, 0.05, 0.7)))
