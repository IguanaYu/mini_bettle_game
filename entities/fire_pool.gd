class_name FirePool
extends Node2D
## 燃烧区域：纯视觉与状态持有；tick 采样伤害由 FireEggManager 结算（FirePool 不自行伤人）。
## 圈内火焰呼吸、tick 命中瞬间提亮、寿命末端淡出——消散本身不造成伤害（火系武器扩展设计 W07）。

const FLAME_COUNT := 8

var rule: FireEggRule   # 生成时快照：升级不影响已落地的火池
var age := 0.0
var tick_acc := 0.0
var flash := 0.0        # tick 结算后的提亮余量，由管理器衰减
var dead := false
var phases: Array[float] = []


func setup_visual() -> void:
	## 火苗相位取自统一随机服务（种子可控）；只影响呼吸节奏，不影响判定
	for i in FLAME_COUNT:
		phases.append(Rng.randf_range(0.0, TAU))


func _draw() -> void:
	var d := maxf(rule.pool_duration, 0.001)
	var k := clampf(age / 0.15, 0.0, 1.0) * clampf((d - age) / 0.4, 0.0, 1.0)
	if k <= 0.0:
		return
	var r := rule.pool_radius
	# 地面灼烧层：内淡外亮的圈
	draw_circle(Vector2.ZERO, r, Palette.c(Color(1.0, 0.45, 0.12, 0.10 * k)))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Palette.c(Color(1.0, 0.55, 0.15, 0.75 * k)), 3.0)
	draw_arc(Vector2.ZERO, r * 0.6, 0.0, TAU, 32, Palette.c(Color(1.0, 0.70, 0.30, 0.30 * k)), 2.0)
	# 环上火焰：固定相位各自呼吸，整体缓慢旋转
	for i in phases.size():
		var pulse := 0.5 + 0.5 * sin(age * 7.0 + phases[i])
		var ang := TAU * float(i) / float(phases.size()) + age * 0.6
		var pos := Vector2.from_angle(ang) * r * (0.72 + 0.22 * pulse)
		var col := Color(1.0, 0.60, 0.15, 0.85 * k) if i % 2 == 0 \
				else Color(1.0, 0.82, 0.40, 0.90 * k)
		draw_circle(pos, 3.0 + 2.5 * pulse, Palette.c(col))
	# tick 结算瞬间的提亮环：伤害与视觉同时发生
	if flash > 0.0:
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40,
				Palette.c(Color(1.0, 0.90, 0.55, 0.5 * flash * k)), 5.0)
