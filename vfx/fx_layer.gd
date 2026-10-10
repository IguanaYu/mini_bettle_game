class_name FxLayer
extends Node2D
## 短时特效统一挂载/回收；活跃数供试验面板显示（开发方案 5.7 / 9.4）。
## 特效由 Arena._step → fx_layer.tick 驱动，特效结束永远不是伤害结算条件。

func fx_count() -> int:
	return get_child_count()


func tick(delta: float) -> void:
	for c in get_children():
		c.tick(delta)
	for c in get_children():
		if c.done:
			c.queue_free()


func spawn_muzzle(pos: Vector2, dir: Vector2, profile: VfxProfile) -> void:
	var fx := MuzzleFx.new()
	fx.setup(pos, dir, profile)
	add_child(fx)


func spawn_hit(pos: Vector2, profile: VfxProfile) -> void:
	var fx := HitFx.new()
	fx.setup(pos, profile, false)
	add_child(fx)


func spawn_expire(pos: Vector2, profile: VfxProfile) -> void:
	## 未命中到期：较轻的消散，与命中反馈区分（设计文档 6.4）
	var fx := HitFx.new()
	fx.setup(pos, profile, true)
	add_child(fx)


func spawn_trail(points: Array, profile: VfxProfile) -> void:
	## 弹体结束后残留的尾迹，逐步减弱（设计文档 10.4）
	if points.is_empty():
		return
	var fx := TrailGhost.new()
	fx.setup(points, profile)
	add_child(fx)


class FxBase:
	extends Node2D
	var done := false
	func tick(_delta: float) -> void:
		pass


class MuzzleFx:
	extends FxBase
	var t := 0.0
	var life := 0.06
	var sparks := false
	var spark_dirs: Array[Vector2] = []

	func setup(pos: Vector2, dir: Vector2, profile: VfxProfile) -> void:
		position = pos
		life = maxf(profile.muzzle_flash_time, 0.01)
		sparks = profile.muzzle_sparks
		for i in 6:
			spark_dirs.append(dir.rotated(Rng.randf_range(-0.9, 0.9)))

	func tick(delta: float) -> void:
		t += delta
		if t >= life + (0.1 if sparks else 0.0):
			done = true
		queue_redraw()

	func _draw() -> void:
		var k := clampf(1.0 - t / life, 0.0, 1.0)
		draw_circle(Vector2.ZERO, 6.0 + 8.0 * (1.0 - k), Palette.c(Color(1.0, 0.8, 0.4, 0.8 * k)))
		if sparks:
			for d in spark_dirs:
				var tip: Vector2 = d * (10.0 + 55.0 * t * 10.0)
				draw_line(d * 6.0, tip, Palette.c(Color(1.0, 0.6, 0.2, k)), 2.0)


class HitFx:
	extends FxBase
	var t := 0.0
	var life := 0.18
	var max_r := 24.0
	var base_r := 10.0
	var ember_life := 0.15
	var embers: Array[Vector2] = []
	var weak := false

	func setup(pos: Vector2, profile: VfxProfile, p_weak: bool) -> void:
		position = pos
		weak = p_weak
		life = 0.12 if weak else maxf(profile.hit_flash_time, 0.01)
		max_r = profile.body_radius + 4.0 if weak else profile.hit_max_radius
		base_r = profile.body_radius
		ember_life = 0.0 if weak else profile.ember_lifetime
		for i in 6:
			embers.append(Vector2(Rng.randf_range(-1, 1), Rng.randf_range(-1, 1)).normalized())

	func tick(delta: float) -> void:
		t += delta
		if t >= maxf(life, ember_life):
			done = true
		queue_redraw()

	func _draw() -> void:
		var k := clampf(1.0 - t / life, 0.0, 1.0)
		var r: float = lerpf(base_r, max_r, 1.0 - k)
		var strong := 0.85 if not weak else 0.3
		draw_circle(Vector2.ZERO, r, Palette.c(Color(1.0, 0.7, 0.25, strong * k)))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Palette.c(Color(1.0, 0.9, 0.5, strong * k)), 2.0)
		if ember_life > 0.0 and t < ember_life:
			var ek := clampf(1.0 - t / ember_life, 0.0, 1.0)
			for d in embers:
				draw_circle(d * (20.0 + 110.0 * t), 2.5 * ek + 1.0,
						Palette.c(Color(1.0, 0.45, 0.10, 0.8 * ek)))


class TrailGhost:
	extends FxBase
	var t := 0.0
	var life := 0.12
	var points: Array[Vector2] = []

	func setup(pts: Array, profile: VfxProfile) -> void:
		points.assign(pts)
		life = maxf(profile.trail_lifetime, 0.01)

	func tick(delta: float) -> void:
		t += delta
		if t >= life:
			done = true
		queue_redraw()

	func _draw() -> void:
		var fade := clampf(1.0 - t / life, 0.0, 1.0)
		var n := points.size()
		for i in n:
			var k := float(i + 1) / float(n)
			draw_circle(points[i] - position, 5.5 * k,
					Palette.c(Color(1.0, 0.5, 0.15, 0.3 * k * fade)))
		position = Vector2.ZERO  # ghost 挂在世界原点下，用世界坐标绘制
