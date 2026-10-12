class_name FireEggManager
extends Node
## W07 火蛋控制器（火系武器扩展设计）：慢速弹体推进 + 终点生成燃烧区域 + 火池 tick 结算。
## 火蛋本体不直接造成伤害；命中/撞墙/到期统一生成火池（诚实范围：池心钳制使整池在场内）。

var arena: Arena
var rule: FireEggRule
var active := false
var auto_fire := true
var cooldown := 0.0
var eggs: Array[FireEgg] = []
var pools: Array[FirePool] = []


func setup(a: Arena, r: FireEggRule) -> void:
	arena = a
	rule = r


func activate(r: FireEggRule) -> void:
	rule = r
	active = true
	cooldown = 0.0


func tick(delta: float) -> void:
	if active and auto_fire:
		cooldown -= delta
		if cooldown <= 0.0:
			var target := find_target()
			if target != null:
				fire_at(target)
				cooldown += rule.fire_interval
			else:
				cooldown = 0.0
	for egg in eggs:
		_advance(egg, delta)
	for pool in pools:
		_tick_pool(pool, delta)
	_sweep()


## 与火球同规则：range 内最近存活敌，并列取生成序号较小者（设计文档 6.1）
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


func fire_at(target: Node2D) -> FireEgg:
	return fire_dir((target.position - arena.player.position).normalized())


func fire_dir(dir: Vector2) -> FireEgg:
	var egg := FireEgg.new()
	egg.attack_id = arena.alloc_attack_id()
	egg.rule = rule          # 发射时快照
	egg.visual = arena.projectiles.current_visual
	egg.position = arena.player.position
	egg.dir = dir if dir.length() > 0.0001 else Vector2.RIGHT
	arena.projectiles_node.add_child(egg)
	eggs.append(egg)
	arena.fx_layer.spawn_muzzle(egg.position, egg.dir, arena.projectiles.current_visual)
	EventBus.attack_fired.emit(rule.element, egg.attack_id, egg.position, egg.dir)
	return egg


func _advance(egg: FireEgg, delta: float) -> void:
	if egg.dead:
		return
	var prev := egg.position
	egg.position += egg.dir * egg.rule.projectile_speed * delta
	egg.age += delta
	egg.record_trail()
	# 扫掠检测：命中敌人 → 原地生成燃烧区域（本体不结算伤害）
	for e in arena.enemies:
		if e.state != GameEnums.EnemyState.ALIVE:
			continue
		var t := Geo.segment_hit_t(prev, egg.position, e.position,
				egg.rule.hit_radius + e.radius)
		if t >= 0.0:
			egg.position = prev + (egg.position - prev) * t
			_detonate(egg)
			return
	# 撞墙：蛋停在墙内侧，燃烧区域钳制在场地内
	if not Arena.arena_inner_rect().has_point(egg.position):
		egg.position = egg.position.clamp(
				Arena.arena_inner_rect().position, Arena.arena_inner_rect().end)
		_detonate(egg)
		return
	# 到期：空中烧尽，原地生成燃烧区域
	if egg.age >= egg.rule.lifetime:
		_detonate(egg)


func _detonate(egg: FireEgg) -> void:
	egg.dead = true
	arena.fx_layer.spawn_hit(egg.position, egg.visual)
	_spawn_pool(_clamp_pool_center(egg.position, egg.rule.pool_radius), egg.rule, egg.visual)


func _clamp_pool_center(pos: Vector2, pool_radius: float) -> Vector2:
	## 整池收进内区：诚实范围（池圈即伤害圈，不藏进墙里）
	var r := Arena.arena_inner_rect().grow(-pool_radius)
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return pos
	return pos.clamp(r.position, r.end)


func _spawn_pool(pos: Vector2, r: FireEggRule, visual: VfxProfile = null) -> void:
	if pools.size() >= r.max_pools:
		# 同屏上限：最旧一片提前熄灭（防长局对象积累，火系武器扩展设计 W04 条款）
		pools[0].dead = true
	var pool := FirePool.new()
	pool.rule = r
	pool.visual = visual if visual != null else arena.projectiles.current_visual
	pool.position = pos
	pool.setup_visual()
	arena.projectiles_node.add_child(pool)
	pools.append(pool)


func _tick_pool(pool: FirePool, delta: float) -> void:
	if pool.dead:
		return
	pool.tick_acc += delta
	if pool.tick_acc >= pool.rule.pool_tick_interval:
		pool.tick_acc -= pool.rule.pool_tick_interval
		_burn_tick(pool)
	pool.age += delta
	pool.flash = maxf(0.0, pool.flash - delta * 5.0)
	if pool.age >= pool.rule.pool_duration:
		pool.dead = true
	pool.queue_redraw()


func _burn_tick(pool: FirePool) -> void:
	## 每跳一个新的 attack_id：同一敌人可被逐跳反复灼烧（每次采样至多一次）
	var tick_id := arena.alloc_attack_id()
	var hit_any := false
	for e in arena.enemies:
		if e.state != GameEnums.EnemyState.ALIVE:
			continue
		if e.position.distance_to(pool.position) <= pool.rule.pool_radius + e.radius:
			DamageResolver.apply_damage(e, pool.rule.pool_damage, tick_id,
					pool.rule.element, arena)
			hit_any = true
	if hit_any:
		pool.flash = 1.0


func _sweep() -> void:
	for i in range(eggs.size() - 1, -1, -1):
		if eggs[i].dead:
			eggs[i].queue_free()
			eggs.remove_at(i)
	for i in range(pools.size() - 1, -1, -1):
		if pools[i].dead:
			pools[i].queue_free()
			pools.remove_at(i)


func clear() -> void:
	## 清场：火蛋与火池（重开/重置共用）
	for egg in eggs:
		egg.queue_free()
	eggs.clear()
	for pool in pools:
		pool.queue_free()
	pools.clear()
	cooldown = 0.0
