class_name ProjectileManager
extends Node
## 火球发射与推进：自动瞄准 + 扫掠连续命中检测（开发方案 5.3）。

var arena: Arena
var rule: AttackRule            # 运行时副本：升级与试验面板改这里
var current_visual: VfxProfile  # A/B 切换只影响之后生成的弹体（设计文档 9.3）
var auto_fire := true
var cooldown := 0.0
var balls: Array[Fireball] = []


func setup(a: Arena, r: AttackRule, v: VfxProfile) -> void:
	arena = a
	rule = r
	current_visual = v


func set_rule(r: AttackRule) -> void:
	## 从基础规则重建运行时副本（重开/重置用，开发方案 8 风险表）
	rule = r
	cooldown = 0.0


func tick(delta: float) -> void:
	if auto_fire:
		cooldown -= delta
		if cooldown <= 0.0:
			var target := find_target()
			if target != null:
				fire_at(target)
				# 用 += 而不是 =：掉帧时不意外提高攻速（开发方案 8 风险表）
				cooldown += rule.fire_interval
			else:
				# 无有效目标不生成火球，进入下一次正常间隔（设计文档 6.1）
				cooldown = 0.0
	for b in balls:
		_advance(b, delta)
	_sweep_dead()


## 900px 内最近的存活敌人；距离相同时取生成序号较小者（设计文档 6.1）
func find_target() -> Enemy:
	var best: Enemy = null
	var best_d := rule.aim_range + 1.0
	for e in arena.enemies:
		if e.state != GameEnums.EnemyState.ALIVE:
			continue
		var d := e.position.distance_to(arena.player.position)
		if d > rule.aim_range:
			continue
		if d < best_d or (is_equal_approx(d, best_d) and best != null and e.id < best.id):
			best = e
			best_d = d
	return best


func fire_at(target: Node2D) -> Fireball:
	var dir: Vector2 = (target.position - arena.player.position).normalized()
	return fire_dir(dir)


func fire_forward() -> Fireball:
	## 试验模式无目标时的固定方向发射
	return fire_dir(Vector2.RIGHT)


func fire_dir(dir: Vector2, r: AttackRule = null, with_muzzle := true,
		emit_event := true) -> Fireball:
	## r 非空时以外部规则快照生成（散射火球复用本推进管线，火系武器扩展设计 W01）；
	## with_muzzle/emit_event 供齐射避免逐弹重复表现，由调用方统一发一次。
	var rr := r if r != null else rule
	var b := Fireball.new()
	b.attack_id = arena.alloc_attack_id()
	b.rule = rr             # 发射时快照
	b.visual = current_visual
	b.position = arena.player.position
	b.dir = dir if dir.length() > 0.0001 else Vector2.RIGHT
	arena.projectiles_node.add_child(b)
	balls.append(b)
	if with_muzzle:
		arena.fx_layer.spawn_muzzle(b.position, b.dir, current_visual)
	if emit_event:
		EventBus.attack_fired.emit(rr.element, b.attack_id, b.position, b.dir)
	return b


func live_ball_count() -> int:
	var n := 0
	for b in balls:
		if not b.dead:
			n += 1
	return n


func _advance(b: Fireball, delta: float) -> void:
	if b.dead:
		return
	var prev := b.position
	b.position += b.dir * b.rule.projectile_speed * delta
	b.age += delta
	b.record_trail()
	# 到期消散：不触发命中伤害（设计文档 6.2）
	if b.age >= b.rule.lifetime:
		_expire(b)
		return
	# 撞墙消散：封闭场地内弹体不出界（Brotato 式）
	if not Arena.arena_inner_rect().has_point(b.position):
		_expire(b)
		return
	# 扫掠检测：本帧路径上的最早交点（验收 A03）
	var best_t := 1e9
	var best_enemy: Enemy = null
	for e in arena.enemies:
		if e.state != GameEnums.EnemyState.ALIVE:
			continue
		if b.hit_targets.has(e.id):
			continue
		var t := Geo.segment_hit_t(prev, b.position, e.position, b.rule.hit_radius + e.radius)
		if t >= 0.0 and t < best_t:
			best_t = t
			best_enemy = e
	if best_enemy != null:
		b.position = prev + (b.position - prev) * best_t  # 停在命中点
		var hit := DamageResolver.apply_damage(best_enemy, b.rule.damage,
				b.attack_id, b.rule.element, arena)
		if hit:
			b.hit_targets[best_enemy.id] = true
			arena.fx_layer.spawn_hit(b.position, b.visual)
			if b.pierced < b.rule.pierce:
				b.pierced += 1  # 穿透：继续飞行
			else:
				_destroy(b)
				return
	b.queue_redraw()


func _expire(b: Fireball) -> void:
	b.dead = true
	arena.fx_layer.spawn_expire(b.position, b.visual)
	arena.fx_layer.spawn_trail(b.trail_snapshot(), b.visual)
	EventBus.attack_expired.emit(b.attack_id, b.position, b.rule.element)


func _destroy(b: Fireball) -> void:
	b.dead = true
	arena.fx_layer.spawn_trail(b.trail_snapshot(), b.visual)


func _sweep_dead() -> void:
	for i in range(balls.size() - 1, -1, -1):
		if balls[i].dead:
			balls[i].queue_free()
			balls.remove_at(i)


func clear_balls() -> void:
	for b in balls:
		b.queue_free()
	balls.clear()
