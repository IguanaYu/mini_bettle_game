class_name FirePool
extends Node2D
## 燃烧区域：纯视觉与状态持有；tick 采样伤害由 FireEggManager 结算（FirePool 不自行伤人）。
## 圈内火焰呼吸、tick 命中瞬间提亮、寿命末端淡出——消散本身不造成伤害（火系武器扩展设计 W07）。

const FLAME_COUNT := 8

var rule: FireEggRule   # 生成时快照：升级不影响已落地的火池
var visual: VfxProfile
var age := 0.0
var tick_acc := 0.0
var flash := 0.0        # tick 结算后的提亮余量，由管理器衰减
var dead := false
var phases: Array[float] = []


func _ready() -> void:
	z_index = -12
	GameArt.apply_world_material(self)


func setup_visual() -> void:
	# Stable visual phases avoid consuming the gameplay random sequence.
	for i in FLAME_COUNT:
		phases.append(fmod(float(i) * 2.399 + position.x * 0.01 + position.y * 0.02, TAU))


func _draw() -> void:
	var d := maxf(rule.pool_duration, 0.001)
	var k := clampf(age / 0.15, 0.0, 1.0) * clampf((d - age) / 0.4, 0.0, 1.0)
	if k <= 0.0:
		return
	var r := rule.pool_radius
	var b := visual.brightness if visual != null else 1.0
	var pulse := 0.92 + sin(age * 6.0) * 0.035 + flash * 0.10
	draw_texture_rect(GameArt.trimmed(GameArt.BURNING_GROUND), Rect2(-Vector2.ONE * r, Vector2.ONE * r * 2.0),
			false, Color(b * pulse, b * pulse, b * pulse, k * 0.88))
	# The boundary stays fixed at the rule radius while interior flames move.
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Palette.c(Color(1.0, 0.67, 0.23, 0.5 * k)), 1.2, true)
	for i in phases.size():
		var flicker := 0.5 + 0.5 * sin(age * 8.0 + phases[i])
		var ang := TAU * float(i) / float(phases.size())
		var pos := Vector2.from_angle(ang) * r * 0.64
		var size := Vector2(r * 0.34, r * (0.28 + flicker * 0.16))
		draw_texture_rect(GameArt.fire(3), Rect2(pos - size * 0.5, size),
				false, Color(b, b, b, k * (0.4 + flicker * 0.4)))
	if flash > 0.0:
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40,
				Palette.c(Color(1.0, 0.90, 0.55, 0.5 * flash * k)), 2.0, true)
