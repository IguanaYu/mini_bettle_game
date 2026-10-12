class_name FxLayer
extends Node2D
## 短时特效统一挂载/回收；活跃数供试验面板显示（开发方案 5.7 / 9.4）。
## 特效由 Arena._step → fx_layer.tick 驱动，特效结束永远不是伤害结算条件。

func fx_count() -> int:
	var count := 0
	for fx in get_children():
		if not fx.done and not fx.is_queued_for_deletion():
			count += 1
	return count


func tick(delta: float) -> void:
	for c in get_children():
		if not c.is_queued_for_deletion():
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
	func _ready() -> void:
		GameArt.apply_world_material(self)
	func tick(_delta: float) -> void:
		pass


class MuzzleFx:
	extends FxBase
	var t := 0.0
	var life := 0.06
	var sparks := false
	var spark_dirs: Array[Vector2] = []
	var brightness := 1.0
	var radius := 10.0

	func setup(pos: Vector2, dir: Vector2, profile: VfxProfile) -> void:
		position = pos + dir * 12.0 + Vector2(0, -7)
		rotation = dir.angle()
		life = maxf(profile.muzzle_flash_time, 0.01)
		sparks = profile.muzzle_sparks
		brightness = profile.brightness
		radius = profile.body_radius
		for i in 6:
			spark_dirs.append(Vector2.RIGHT.rotated(lerpf(-0.9, 0.9, float(i) / 5.0)))

	func tick(delta: float) -> void:
		t += delta
		if t >= life + (0.1 if sparks else 0.0):
			done = true
		queue_redraw()

	func _draw() -> void:
		var k := clampf(1.0 - t / life, 0.0, 1.0)
		var size := radius * (1.8 + 0.8 * (1.0 - k))
		draw_texture_rect(GameArt.fire(0), Rect2(-Vector2.ONE * size * 0.5, Vector2.ONE * size),
				false, Color(brightness, brightness, brightness, k))
		if sparks:
			var spark_k := clampf(1.0 - t / (life + 0.1), 0.0, 1.0)
			for d in spark_dirs:
				var tip: Vector2 = d * (6.0 + 160.0 * t)
				draw_line(tip - d * 4.0, tip, Palette.c(Color(1.0, 0.7, 0.25, spark_k)), 1.3, true)


class HitFx:
	extends FxBase
	var t := 0.0
	var life := 0.18
	var max_r := 24.0
	var base_r := 10.0
	var ember_life := 0.15
	var embers: Array[Vector2] = []
	var weak := false
	var brightness := 1.0

	func setup(pos: Vector2, profile: VfxProfile, p_weak: bool) -> void:
		position = pos
		weak = p_weak
		brightness = profile.brightness
		life = 0.12 if weak else maxf(profile.hit_flash_time, 0.01)
		max_r = profile.body_radius + 4.0 if weak else profile.hit_max_radius
		base_r = profile.body_radius
		ember_life = 0.0 if weak else profile.ember_lifetime
		for i in 6:
			embers.append(Vector2.from_angle(float(i) * TAU / 6.0 + pos.x * 0.01 + pos.y * 0.007))

	func tick(delta: float) -> void:
		t += delta
		if t >= maxf(life, ember_life):
			done = true
		queue_redraw()

	func _draw() -> void:
		var k := clampf(1.0 - t / life, 0.0, 1.0)
		var progress := 1.0 - k
		var r: float = lerpf(base_r * 0.65, max_r, 1.0 - pow(k, 3.0))
		var alpha := k * (0.55 if weak else 1.0)
		draw_set_transform(Vector2.ZERO, progress * 0.18, Vector2.ONE)
		draw_texture_rect(GameArt.fire(3 if weak else 2), Rect2(-Vector2.ONE * r, Vector2.ONE * r * 2.0),
				false, Color(brightness, brightness, brightness, alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if not weak and t < 0.04:
			draw_circle(Vector2.ZERO, 3.0 * k, Palette.c(Color(1.0, 0.96, 0.75, k * 0.65)))
		if ember_life > 0.0 and t < ember_life:
			var ek := clampf(1.0 - t / ember_life, 0.0, 1.0)
			for d in embers:
				var tip := d * (base_r * 0.5 + 70.0 * t)
				draw_line(tip - d * (1.0 + 3.0 * ek), tip,
						Palette.c(Color(1.0, 0.68, 0.20, 0.7 * ek)), 1.0 + ek, true)


class TrailGhost:
	extends FxBase
	var t := 0.0
	var life := 0.12
	var points: Array[Vector2] = []
	var radius := 10.0
	var brightness := 1.0

	func setup(pts: Array, profile: VfxProfile) -> void:
		points.assign(pts)
		life = maxf(profile.trail_lifetime, 0.01)
		radius = profile.body_radius
		brightness = profile.brightness

	func tick(delta: float) -> void:
		t += delta
		if t >= life:
			done = true
		queue_redraw()

	func _draw() -> void:
		var fade := clampf(1.0 - t / life, 0.0, 1.0)
		var n := points.size()
		for i in range(0, n, 3):
			var k := float(i + 1) / float(n)
			var size := radius * (0.5 + k)
			draw_texture_rect(GameArt.fire(3), Rect2(points[i] - Vector2.ONE * size * 0.5, Vector2.ONE * size),
					false, Color(brightness, brightness, brightness, 0.28 * k * fade))
