class_name Arena
extends Node2D
## 战斗场地（生存与试验共用）。世界推进的唯一入口：_process → _step（开发方案 4.2）。
## 一切 gameplay 更新（玩家/敌人/弹体/特效/经验）都在 _step 内按固定顺序推进，
## 测试通过 step_manual 以固定步长驱动。
##
## 封闭竞技场（Brotato 式）：固定大小、四面墙、全场可见，相机固定在场心。

const ARENA_HALF := Vector2(640.0, 360.0)  # 场地半尺寸 = 设计视口 1280x720
const WALL := 24.0                          # 墙厚；可行动区为内区矩形


static func arena_inner_rect() -> Rect2:
	## 可行动区（墙内侧）；刷怪、钳制、弹体消散都以它为准
	return Rect2(-ARENA_HALF + Vector2(WALL, WALL), (ARENA_HALF - Vector2(WALL, WALL)) * 2.0)

var is_experiment := false
var world_time := 0.0          # 试验模式的世界时钟（生存模式用 Game.run.elapsed）

var player: Player
var camera: Camera2D
var ground: Ground
var fx_layer: FxLayer
var debug_draw: DebugDraw
var spawner: Spawner
var projectiles: ProjectileManager
var xp_manager: XpManager
var upgrades: UpgradeSystem

var enemies: Array[Enemy] = []
var projectiles_node: Node2D

var player_def: PlayerDef
var enemy_def: EnemyDef
var fireball_rule_base: AttackRule  # 未修改原型：重开/重置时从这里 duplicate
var visual_a_base: VfxProfile      # 视觉基线：试验改参后从这里还原
var visual_b_base: VfxProfile
var visual_a: VfxProfile
var visual_b: VfxProfile
var camera_static := false     # 兼容保留：试验模式置 true（A11/A13 断言）；相机现在恒定不动


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	player_def = (load("res://balance/player_default.tres") as PlayerDef).duplicate()
	enemy_def = (load("res://balance/enemy_default.tres") as EnemyDef).duplicate()
	fireball_rule_base = load("res://balance/fireball_rule.tres")
	visual_a_base = load("res://balance/vfx_fireball_a.tres")
	visual_b_base = load("res://balance/vfx_fireball_b.tres")
	visual_a = visual_a_base.duplicate()
	visual_b = visual_b_base.duplicate()

	ground = Ground.new()
	ground.arena = self
	add_child(ground)

	player = Player.new()
	player.setup(player_def)
	add_child(player)

	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()

	projectiles_node = Node2D.new()
	add_child(projectiles_node)

	fx_layer = FxLayer.new()
	add_child(fx_layer)

	debug_draw = DebugDraw.new()
	debug_draw.arena = self
	debug_draw.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(debug_draw)

	projectiles = ProjectileManager.new()
	add_child(projectiles)
	projectiles.setup(self, fireball_rule_base.duplicate(), visual_a)

	spawner = Spawner.new()
	add_child(spawner)
	spawner.setup(self)

	xp_manager = XpManager.new()
	add_child(xp_manager)
	xp_manager.setup(self)

	upgrades = UpgradeSystem.new()
	add_child(upgrades)
	upgrades.setup(self)


func _process(delta: float) -> void:
	_step(delta)


func step_manual(delta: float) -> void:
	## 测试入口：固定步长推进（同时关闭引擎驱动）
	set_process(false)
	_step(delta)


func _step(delta: float) -> void:
	if not Game.is_playing():
		return
	world_time += delta
	if not is_experiment and Game.run != null:
		Game.run.elapsed += delta

	if not is_experiment and Game.run != null and not Game.run.finished:
		# 死亡优先于满 300 秒；结算只发生一次（设计文档 3.2）
		if player.hp <= 0:
			Game.finish_run(false, "死亡")
		elif Game.run.elapsed >= Game.RUN_DURATION:
			Game.finish_run(true, "生存满300秒")
	if Game.run != null and Game.run.finished:
		return  # 结算后世界停推进

	player.tick(delta)
	_clamp_to_arena(player, player.radius)
	spawner.tick(delta, _elapsed())
	projectiles.tick(delta)
	xp_manager.tick(delta)
	_contact_check()
	for e in enemies:
		e.tick(delta)  # 敌人场内生成、追击场内玩家，直线追击不会出界（A15 回收测试依赖可传送到场外）
	_recycle_far_enemies()
	fx_layer.tick(delta)
	_sweep_dead()


func _elapsed() -> float:
	if is_experiment or Game.run == null:
		return world_time
	return Game.run.elapsed


func _clamp_to_arena(p: Node2D, radius: float) -> void:
	## 封闭场地：实体中心钳在内区内缩 radius 处（墙阻拦）
	var r := arena_inner_rect().grow(-radius)
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	p.position = p.position.clamp(r.position, r.end)


func live_enemy_count() -> int:
	var n := 0
	for e in enemies:
		if e.state != GameEnums.EnemyState.RECYCLED:
			n += 1
	return n


func alive_enemy_count() -> int:
	var n := 0
	for e in enemies:
		if e.state == GameEnums.EnemyState.ALIVE:
			n += 1
	return n


func spawn_target(pos: Vector2, as_target := true) -> Enemy:
	## 生成固定靶（试验靶场与测试用）：不移动、命中结算后回满血
	var e := Enemy.new()
	e.setup(enemy_def, spawner.next_serial(), 0.0, player)
	e.is_target = as_target
	e.position = pos
	add_child(e)
	enemies.append(e)
	EventBus.enemy_spawned.emit(e.id)
	return e


func on_enemy_killed(e: Enemy) -> void:
	## 由 DamageResolver 调用：击杀统计 + 经验掉落（设计文档 7.1）
	if Game.run != null and not is_experiment:
		Game.run.kills += 1
		xp_manager.spawn_gem(e.position, e.def.xp_value)


func clear_world() -> void:
	## 清场：敌人、弹体、特效、经验（重开/重置共用，设计文档 5.6 清理清单）
	for e in enemies:
		e.queue_free()
	enemies.clear()
	projectiles.clear_balls()
	xp_manager.clear_gems()
	for c in fx_layer.get_children():
		c.queue_free()


func restore_visuals() -> void:
	## 视觉参数从基线还原（试验重置用，避免改参污染后续实验）
	visual_a = visual_a_base.duplicate()
	visual_b = visual_b_base.duplicate()


func _contact_check() -> void:
	## 玩家接触伤害：多敌同帧只扣一次（无敌帧保证，验收 A04）
	for e in enemies:
		if e.state != GameEnums.EnemyState.ALIVE or e.is_target:
			continue
		if e.position.distance_to(player.position) < e.radius + player.radius:
			player.try_take_contact_damage(e.def.contact_damage)


func _recycle_far_enemies() -> void:
	## 距玩家超过 1700px 直接回收：无击杀、无经验（设计文档 5.2）
	for e in enemies:
		if e.state == GameEnums.EnemyState.ALIVE and not e.is_target \
				and e.position.distance_to(player.position) > 1700.0:
			e.state = GameEnums.EnemyState.RECYCLED
			EventBus.enemy_recycled.emit(e.id)


func _sweep_dead() -> void:
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].state == GameEnums.EnemyState.RECYCLED:
			enemies[i].queue_free()
			enemies.remove_at(i)
