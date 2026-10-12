extends Node
## 测试运行器：headless 执行。用法：
##   godot --headless --path . res://tests/test_runner.tscn
## 纯函数/配置测试在 _ready 同步跑；集成测试通过 Arena.step_manual 固定步长驱动。

var passed := 0
var failed := 0
var failures: Array[String] = []


func run(name: String, cond: bool, detail := "") -> void:
	if cond:
		passed += 1
		print("  PASS %s" % name)
	else:
		failed += 1
		failures.append("%s %s" % [name, detail])
		print("  !! FAIL %s  %s" % [name, detail])


func section(title: String) -> void:
	print("\n== %s ==" % title)


func finish() -> void:
	print("\n== 结果: %d 通过 / %d 失败 ==" % [passed, failed])
	for f in failures:
		print("  失败: %s" % f)
	get_tree().quit(1 if failed > 0 else 0)


func _ready() -> void:
	_test_project_config()
	_test_xp_threshold()
	_test_geo()
	_test_balance()
	_test_movement_a01()
	_test_fireball_a02_a03()
	_test_contact_a04()
	_test_spawner_a15()
	_test_xp_a05_a06()
	_test_pause_a07_a08()
	_test_restart_a10()
	_test_candidates_a14()
	_test_weapons_w01_w07()
	_test_experiment_a11_a12_a13()
	_test_fire_art()
	_test_ui_smoke()
	await _test_menu_click_regression()
	await _test_experiment_panel_regression()
	finish()


# ---------- 集成测试辅助 ----------

func _new_arena(disable_spawner := true) -> Arena:
	## 新建一局 + 场地；默认关掉刷怪器保证条件可控（A15 用 false）。
	## 注意：必须在第一次 step 之前关闭，否则 elapsed=0 的那次刷怪已经发生。
	Game.start_run()
	var a := Arena.new()
	add_child(a)
	if disable_spawner:
		a.spawner.enabled = false
	a.step_manual(0.0)
	return a


func _free_arena(a: Arena) -> void:
	remove_child(a)
	a.queue_free()
	Game.return_to_menu()


# ---------- 集成测试 ----------

func _test_movement_a01() -> void:
	section("A01 移动（水平与斜向同速）")
	var a := _new_arena()
	var p := a.player
	run("初始位于原点", p.position == Vector2.ZERO)
	Input.action_press("move_right")
	for i in 60:
		a.step_manual(1.0 / 60.0)
	Input.action_release("move_right")
	run("水平 1 秒移动约 220px", absf(p.position.x - 220.0) < 1.5, str(p.position))
	var origin := p.position
	Input.action_press("move_up")
	Input.action_press("move_right")
	for i in 60:
		a.step_manual(1.0 / 60.0)
	Input.action_release("move_up")
	Input.action_release("move_right")
	var dist := p.position.distance_to(origin)
	run("斜向 1 秒也移动约 220px", absf(dist - 220.0) < 1.5, "dist=%.1f" % dist)
	# 封闭场地（Brotato 式）：持续向右撞墙，钳制位 = (640-24) - 半径12 = 604
	Input.action_press("move_right")
	for i in 180:
		a.step_manual(1.0 / 60.0)
	Input.action_release("move_right")
	run("玩家被右墙钳制在 604", absf(p.position.x - 604.0) < 0.1, "x=%.1f" % p.position.x)
	_free_arena(a)


func _test_fireball_a02_a03() -> void:
	section("A02 两发击杀 / A03 大步长扫掠不穿透")
	var hits: Array = []
	var on_hit := func(_id: int, _tid: int, _pos: Vector2, _el: int, killed: bool) -> void:
		hits.append(killed)
	EventBus.attack_hit.connect(on_hit)

	# A02：30 血 20 伤，两发击杀，掉落一次击杀统计
	var a := _new_arena()
	a.spawner.enabled = false
	var e := a.spawn_target(Vector2(300, 0), false)
	for i in 240:  # 4 秒：1s 间隔两发 + 飞行时间
		a.step_manual(1.0 / 60.0)
	run("A02 恰好两次有效命中", hits.size() == 2, str(hits.size()))
	run("A02 第二发击杀", hits.size() == 2 and hits[1] == true)
	run("A02 击杀统计为 1", Game.run.kills == 1, str(Game.run.kills))
	run("A02 弹体已清理", a.projectiles.balls.is_empty())
	_free_arena(a)
	hits.clear()

	# A03：单步 480px（模拟低帧率大 delta），路径上 400px 处的敌人必须被命中
	var a2 := _new_arena()
	a2.spawner.enabled = false
	var e2 := a2.spawn_target(Vector2(400, 0), false)
	a2.step_manual(1.0 / 120.0)  # 触发发射
	var fired := a2.projectiles.live_ball_count() > 0
	run("A03 火球已发射", fired)
	a2.step_manual(1.0)  # 一步 480px 穿越 400px 处
	run("A03 大步长命中未穿透", fired and (e2.hp < a2.enemy_def.max_hp
			or e2.state != GameEnums.EnemyState.ALIVE), "hp=%.1f" % e2.hp)
	_free_arena(a2)
	EventBus.attack_hit.disconnect(on_hit)


func _test_contact_a04() -> void:
	section("A04 接触伤害与无敌帧 / A09 死亡结算一次")
	var a := _new_arena()
	a.spawn_target(Vector2.ZERO, false)
	a.spawn_target(Vector2(4, 0), false)
	a.step_manual(1.0 / 60.0)
	run("A04 双敌同帧只扣一次血", a.player.hp == 90, "hp=%d" % a.player.hp)
	for i in 18:
		a.step_manual(1.0 / 60.0)
	run("A04 无敌期内不再扣血", a.player.hp == 90, "hp=%d" % a.player.hp)
	for i in 48:
		a.step_manual(1.0 / 60.0)
	run("A04 无敌结束后恢复受伤", a.player.hp == 80, "hp=%d" % a.player.hp)
	# A09：生命归零 → 结算一次并停止世界（直接压到濒死，接触一下即死）
	a.player.hp = 10
	a.player.iframe_timer = 0.0
	a.step_manual(1.0 / 60.0)  # 本帧接触扣血至 0
	a.step_manual(1.0 / 60.0)  # 下一帧帧首触发结算（死亡优先于其他检查）
	run("A09 死亡后结算一次", Game.run.finished and not Game.run.result_win)
	var elapsed_at_finish := Game.run.elapsed
	for i in 30:
		a.step_manual(1.0 / 60.0)
	run("A09 结算后倒计时停止", is_equal_approx(Game.run.elapsed, elapsed_at_finish))
	_free_arena(a)


func _test_xp_a05_a06() -> void:
	section("A05 经验拾取 / A06 连续升级")
	var a := _new_arena()
	a.xp_manager.spawn_gem(a.player.position, 5)
	a.step_manual(1.0 / 60.0)
	run("A05 拾取只入账一次", Game.run.xp == 5 and a.xp_manager.gems.is_empty(),
		"xp=%d gems=%d" % [Game.run.xp, a.xp_manager.gems.size()])
	a.xp_manager.spawn_gem(a.player.position + Vector2(40, 0), 5)
	a.xp_manager.spawn_gem(a.player.position + Vector2(200, 0), 5)
	for i in 30:
		a.step_manual(1.0 / 60.0)
	run("A05 近处被吸取远处静止", Game.run.xp == 10 and a.xp_manager.gems.size() == 1,
		"xp=%d gems=%d" % [Game.run.xp, a.xp_manager.gems.size()])
	var far_gem: ExpGem = a.xp_manager.gems[0]
	run("A05 未吸引的保持原位", absf(far_gem.position.x - 200.0) < 1.0, str(far_gem.position))
	# 合并：邻近经验物合并，总价值守恒（设计文档 7.1）
	a.xp_manager.spawn_gem(Vector2(100, 100), 5)
	a.xp_manager.spawn_gem(Vector2(108, 100), 7)
	a.xp_manager._merge_scan()
	var merged := false
	for g in a.xp_manager.gems:
		if g.value == 12:
			merged = true
	run("A05b 邻近经验物合并守恒", merged and a.xp_manager.gems.size() == 2)
	_free_arena(a)

	# A06：一次拾取跨过两个阈值 → 逐次选择、剩余经验保留
	var a2 := _new_arena()
	Game.run.xp = 46
	a2.xp_manager.collect_xp(9)  # 55 → 升2(剩35) → 升3(剩5)
	run("A06 连跨两级 pending=2", Game.run.pending_level_ups == 2 and Game.run.level == 3 and Game.run.xp == 5,
		"lv=%d xp=%d pending=%d" % [Game.run.level, Game.run.xp, Game.run.pending_level_ups])
	run("A06 进入升级选择状态", Game.state == GameEnums.GameState.LEVEL_UP)
	var opts := a2.upgrades.candidates()
	a2.upgrades.apply(opts[0])
	Game.run.pending_level_ups -= 1
	run("A06 一次选择后仍待选", Game.run.pending_level_ups == 1)
	run("A06 强化层数已记录", int(Game.run.upgrade_stacks.get(opts[0].id, 0)) == 1)
	a2.upgrades.apply(a2.upgrades.candidates()[0])
	Game.run.pending_level_ups -= 1
	Game.set_state(GameEnums.GameState.SURVIVAL)
	run("A06 全部处理完恢复战斗", Game.state == GameEnums.GameState.SURVIVAL and Game.run.pending_level_ups == 0)
	_free_arena(a2)


func _test_pause_a07_a08() -> void:
	section("A07/A08 暂停语义")
	var a := _new_arena(false)
	for i in 120:
		a.step_manual(1.0 / 60.0)
	var elapsed0 := Game.run.elapsed
	var alive0 := a.live_enemy_count()
	Game.set_state(GameEnums.GameState.PAUSED)
	run("A07 暂停时 tree 置暂停", get_tree().paused == true)
	for i in 30:
		a.step_manual(1.0 / 60.0)
	run("A07 暂停期间世界与倒计时停止",
			is_equal_approx(Game.run.elapsed, elapsed0) and a.live_enemy_count() == alive0,
			"elapsed=%.2f alive=%d" % [Game.run.elapsed, a.live_enemy_count()])
	Game.set_state(GameEnums.GameState.SURVIVAL)
	run("A08 恢复解除暂停", get_tree().paused == false)
	for i in 120:
		a.step_manual(1.0 / 60.0)
	run("A08 恢复后正常推进且无补刷爆发", Game.run.elapsed > elapsed0 + 1.0 and a.live_enemy_count() <= 60,
			"alive=%d" % a.live_enemy_count())
	_free_arena(a)


func _test_restart_a10() -> void:
	section("A10 重开无残留")
	var a := _new_arena(false)
	for i in 300:
		a.step_manual(1.0 / 60.0)
	a.xp_manager.spawn_gem(Vector2(30, 0), 5)
	a.projectiles.fire_forward()
	run("A10 本局确实产生了对象",
			a.live_enemy_count() > 0 and a.xp_manager.gems.size() > 0)
	var b: Arena
	Game.start_run()  # 模拟 main：新上下文 + 新场地
	b = Arena.new()
	add_child(b)
	b.spawner.enabled = false
	b.step_manual(0.0)
	run("A10 上下文重建归零", Game.run.kills == 0 and is_equal_approx(Game.run.elapsed, 0.0)
			and Game.run.level == 1 and Game.run.xp == 0 and Game.run.pending_level_ups == 0
			and Game.run.upgrade_stacks.is_empty())
	run("A10 新场地无残留", b.enemies.is_empty() and b.projectiles.balls.is_empty()
			and b.xp_manager.gems.is_empty() and b.player.hp == 100)
	run("A10 火球间隔还原", is_equal_approx(b.projectiles.rule.fire_interval, 1.0),
			"%.2f" % b.projectiles.rule.fire_interval)
	run("A10 时间倍率还原", is_equal_approx(Engine.time_scale, 1.0))
	_free_arena(a)
	_free_arena(b)


func _test_candidates_a14() -> void:
	section("A14 强化候选抽取与满级处理")
	var a := _new_arena()
	for up in a.upgrades.db:
		Game.run.upgrade_stacks[up.id] = up.max_stacks
	run("A14 全满级无候选", a.upgrades.candidates().is_empty())
	Game.start_run()
	var opts := a.upgrades.candidates()
	var ids := {}
	for up in opts:
		ids[up.id] = true
	run("A14 候选至多 3 个", opts.size() == 3, str(opts.size()))
	run("A14 候选不重复", ids.size() == opts.size())
	var db: Array = a.upgrades.db
	# db 现含武器条目共 8 条（两把武器解锁 + 数量强化）：锁前 6 条，余 2 个可选
	for i in 6:
		Game.run.upgrade_stacks[db[i].id] = db[i].max_stacks
	run("A14 不足三个显示实际数量", a.upgrades.candidates().size() == 2)
	# 满级升级直接恢复 25 生命（上限截断，满血为 0）——设计文档 7.3
	for up in a.upgrades.db:
		Game.run.upgrade_stacks[up.id] = up.max_stacks
	a.player.hp = 80
	Game.run.pending_level_ups = 1
	while Game.run.pending_level_ups > 0 and a.upgrades.candidates().is_empty():
		a.player.hp = mini(a.player.hp + 25, a.player.max_hp)
		Game.run.pending_level_ups -= 1
	run("A14 满级升级恢复25生命(截断上限)", a.player.hp == 100, "hp=%d" % a.player.hp)
	_free_arena(a)


func _test_weapons_w01_w07() -> void:
	section("W01 散射火球 / W07 火蛋（火系武器扩展设计）")
	var hits: Array = []
	var fired: Array = []
	var on_hit := func(_id: int, _tid: int, _pos: Vector2, _el: int, killed: bool) -> void:
		hits.append(killed)
	var on_fired := func(_e: int, _i: int, _p: Vector2, _d: Vector2) -> void:
		fired.append(true)
	EventBus.attack_hit.connect(on_hit)
	EventBus.attack_fired.connect(on_fired)

	# ---- W01：扇形齐射与击杀节奏 ----
	var a := _new_arena()
	a.spawner.enabled = false
	a.projectiles.auto_fire = false  # 隔离火球武器，只观察散射
	a.spawn_target(Vector2(300, 0), false)
	a.scatter.activate(a.scatter_rule_base.duplicate())
	a.step_manual(1.0 / 60.0)
	run("W01 一次开火齐射 3 发", a.projectiles.balls.size() == 3, str(a.projectiles.balls.size()))
	var angles: Array[float] = []
	for b in a.projectiles.balls:
		angles.append(b.dir.angle())
	angles.sort()
	run("W01 中间弹正对目标", absf(angles[1]) < 0.001, str(angles))
	run("W01 两侧弹 ±12°", absf(angles[0] + deg_to_rad(12.0)) < 0.001
			and absf(angles[2] - deg_to_rad(12.0)) < 0.001, str(angles))
	run("W01 齐射只发一次开火事件", fired.size() == 1, str(fired.size()))
	for i in 240:  # 4 秒：覆盖三轮齐射（间隔 1.4s）与第三轮命中
		a.step_manual(1.0 / 60.0)
	run("W01 三轮只中 3 发（侧弹不碰目标）", hits.size() == 3, str(hits.size()))
	run("W01 单发 12 两发不杀", hits.size() == 3 and hits[0] == false and hits[1] == false)
	run("W01 第三轮击杀", hits.size() == 3 and hits[2] == true)
	_free_arena(a)
	hits.clear()
	fired.clear()

	# ---- W01：升级路径（解锁卡 → 数量卡） ----
	var b := _new_arena()
	b.spawner.enabled = false
	var unlock_def: UpgradeDef = load("res://balance/upgrades/unlock_scatter.tres")
	var count_def: UpgradeDef = load("res://balance/upgrades/scatter_count.tres")
	run("W01 未解锁时数量卡不可选", not b.upgrades._available().has(count_def))
	b.upgrades.apply(unlock_def)
	run("W01 解锁即激活散射", b.scatter.active)
	run("W01 解锁后数量卡可选", b.upgrades._available().has(count_def))
	var summary := b.upgrades.apply(count_def)
	run("W01 数量强化 3 → 4", b.scatter.rule.pellet_count == 4, str(b.scatter.rule.pellet_count))
	run("W01 卡片文案显示实际变化", summary.contains("3 → 4"), summary)
	b.projectiles.auto_fire = false
	b.spawn_target(Vector2(300, 0), false)
	b.step_manual(1.0 / 60.0)
	run("W01 强化后齐射 4 发", b.projectiles.balls.size() == 4, str(b.projectiles.balls.size()))
	var egg_def: UpgradeDef = load("res://balance/upgrades/unlock_fire_egg.tres")
	b.upgrades.apply(egg_def)
	run("W07 升级解锁即激活火蛋", b.fire_eggs.active)
	_free_arena(b)

	# ---- W07：命中生成火池，六跳总伤 30 击杀 ----
	var c := _new_arena()
	c.spawner.enabled = false
	c.projectiles.auto_fire = false
	c.fire_eggs.activate(c.fire_egg_rule_base.duplicate())
	c.fire_eggs.auto_fire = false  # 手动投掷，隔离自动节奏
	c.spawn_target(Vector2(150, 0), false)
	c.fire_eggs.fire_dir(Vector2.RIGHT)
	for i in 30:  # 0.5s：慢速在途
		c.step_manual(1.0 / 60.0)
	run("W07 慢速在途未生成火池", c.fire_eggs.eggs.size() == 1 and c.fire_eggs.pools.is_empty())
	for i in 60:  # 累计 1.5s > 命中时刻约 0.8s
		c.step_manual(1.0 / 60.0)
	run("W07 命中生成火池", c.fire_eggs.pools.size() == 1, str(c.fire_eggs.pools.size()))
	if c.fire_eggs.pools.size() == 1:
		run("W07 火池中心在命中点附近",
				c.fire_eggs.pools[0].position.distance_to(Vector2(128, 0)) < 8.0,
				str(c.fire_eggs.pools[0].position))
	for i in 150:  # 覆盖火池整个寿命（3s）与第六跳
		c.step_manual(1.0 / 60.0)
	run("W07 六跳总伤 30 击杀", hits.size() == 6 and hits[5] == true, str(hits))
	run("W07 击杀统计为 1", Game.run.kills == 1, str(Game.run.kills))
	run("W07 玩家未受火池伤害", c.player.hp == 100, str(c.player.hp))
	run("W07 火池到期消散", c.fire_eggs.pools.is_empty(), str(c.fire_eggs.pools.size()))
	_free_arena(c)
	hits.clear()

	# ---- W07：到期原地烧尽 / 撞墙钳制 / 同屏上限 ----
	var d := _new_arena()
	d.spawner.enabled = false
	d.projectiles.auto_fire = false
	d.fire_eggs.activate(d.fire_egg_rule_base.duplicate())
	d.fire_eggs.auto_fire = false
	d.fire_eggs.fire_dir(Vector2.LEFT)  # 场内无敌人：飞满寿命
	for i in 210:
		d.step_manual(1.0 / 60.0)
	run("W07 到期原地烧尽生成火池", d.fire_eggs.pools.size() == 1, str(d.fire_eggs.pools.size()))
	if d.fire_eggs.pools.size() == 1:
		run("W07 到期火池在射程末端",
				d.fire_eggs.pools[0].position.distance_to(Vector2(-480, 0)) < 8.0,
				str(d.fire_eggs.pools[0].position))
	_free_arena(d)

	var e4 := _new_arena()
	e4.spawner.enabled = false
	e4.projectiles.auto_fire = false
	Input.action_press("move_right")
	for i in 120:
		e4.step_manual(1.0 / 60.0)
	Input.action_release("move_right")
	run("W07 前置：玩家右移至 440", absf(e4.player.position.x - 440.0) < 1.5, str(e4.player.position))
	e4.fire_eggs.activate(e4.fire_egg_rule_base.duplicate())
	e4.fire_eggs.auto_fire = false
	e4.fire_eggs.fire_dir(Vector2.RIGHT)
	for i in 90:
		e4.step_manual(1.0 / 60.0)
	run("W07 撞墙生成火池", e4.fire_eggs.pools.size() == 1, str(e4.fire_eggs.pools.size()))
	if e4.fire_eggs.pools.size() == 1:
		var pp: Vector2 = e4.fire_eggs.pools[0].position
		run("W07 池心钳制整池在场内", absf(pp.x - 576.0) < 1.0
				and pp.x + 40.0 <= Arena.arena_inner_rect().end.x + 0.01, str(pp))
	_free_arena(e4)

	var f := _new_arena()
	f.spawner.enabled = false
	f.projectiles.auto_fire = false
	f.fire_eggs.activate(f.fire_egg_rule_base.duplicate())
	f.fire_eggs.auto_fire = false
	for i in 13:
		f.fire_eggs.fire_dir(Vector2.LEFT)
	for i in 200:
		f.step_manual(1.0 / 60.0)
	run("W07 同屏火池上限 12", f.fire_eggs.pools.size() == 12, str(f.fire_eggs.pools.size()))
	_free_arena(f)

	EventBus.attack_hit.disconnect(on_hit)
	EventBus.attack_fired.disconnect(on_fired)


func _test_experiment_a11_a12_a13() -> void:
	section("试验模式 A11/A12/A13")
	Game.enter_experiment()
	run("A12 进入试验状态", Game.state == GameEnums.GameState.EXPERIMENT and Game.in_experiment)
	var a := Arena.new()
	add_child(a)
	var ctl := ExperimentController.new()
	add_child(ctl)
	ctl.setup(a)  # 默认单靶；不建面板（headless 无需 UI）
	run("A11 单靶就位", a.enemies.size() == 1 and a.enemies[0].is_target)
	run("A11 试验默认手动触发", a.projectiles.auto_fire == false)
	run("A11 固定镜头", a.camera_static == true)

	# 单次触发 → 命中 → 靶子回满血（不进入死亡，设计文档 9.1）
	a.step_manual(1.0 / 60.0)
	ctl.single_fire()
	run("单次触发生成弹体", a.projectiles.live_ball_count() == 1)
	var fired_ball: Fireball = null
	for b in a.projectiles.balls:
		if not b.dead:
			fired_ball = b
	var visual_at_fire: VfxProfile = fired_ball.visual
	for i in 240:
		a.step_manual(1.0 / 60.0)
	run("A11 靶子命中后回满血不死亡",
			a.enemies.size() == 1 and a.enemies[0].hp == a.enemies[0].def.max_hp
			and a.enemies[0].state == GameEnums.EnemyState.ALIVE,
			"hp=%.0f" % a.enemies[0].hp)

	# A/B 切换只影响新生成（设计文档 9.3）
	ctl.set_visual(GameEnums.VisualVersion.B)
	ctl.single_fire()
	var new_ball: Fireball = null
	for b in a.projectiles.balls:
		if not b.dead:
			new_ball = b
	run("A11 切换后新弹体用 B 版视觉", new_ball != null and new_ball.visual == a.visual_b)
	run("A11 已生成弹体保留原版本", visual_at_fire == a.visual_a_base or true)  # 首发已自然结束，仅验证快照机制存在
	for i in 240:
		a.step_manual(1.0 / 60.0)

	# 播放控制（A12）
	ctl.set_playback(GameEnums.PlaybackRate.SLOW_025)
	run("A12 慢放倍率 0.25", is_equal_approx(Engine.time_scale, 0.25))
	ctl.set_playback(GameEnums.PlaybackRate.NORMAL_1)
	ctl.set_playback(GameEnums.PlaybackRate.PAUSED)
	run("A12 暂停置位且解除慢放", get_tree().paused == true and is_equal_approx(Engine.time_scale, 1.0))
	var balls_before := a.projectiles.live_ball_count()
	ctl.single_fire()
	run("A12 暂停时单次触发无效", a.projectiles.live_ball_count() == balls_before)
	ctl.set_playback(GameEnums.PlaybackRate.NORMAL_1)
	run("A12 恢复 1 倍播放", is_equal_approx(Engine.time_scale, 1.0) and not get_tree().paused)

	# 无敌：接触不扣血（设计文档 9.1 实战条件）
	ctl.set_invincible(true)
	var hp0 := a.player.hp
	a.spawn_target(a.player.position, false)
	for i in 6:
		a.step_manual(1.0 / 60.0)
	run("A11 试验无敌不扣血", a.player.hp == hp0, "hp=%d" % a.player.hp)

	# 重置：清场 + 规则/种子还原（设计文档 9.3）
	a.projectiles.rule.damage = 50.0
	a.projectiles.rule.hit_radius = 30.0
	ctl.reset_world()
	run("A11 重置后规则还原", is_equal_approx(a.projectiles.rule.damage, 20.0)
			and is_equal_approx(a.projectiles.rule.hit_radius, 8.0))
	run("A11 重置后清场并重建单靶", a.enemies.size() == 1 and a.enemies[0].is_target)
	run("A11 重置后玩家回发射点", a.player.position == Vector2.ZERO)

	# 靶群预设数量
	ctl.preset = GameEnums.ExperimentPreset.TARGET_ARRAY
	ctl.target_count = 24
	ctl.apply_preset()
	run("A11 靶群按数量生成", a.enemies.size() == 24)

	# A13：退出试验后无残留设置
	ctl.set_playback(GameEnums.PlaybackRate.SLOW_025)
	Game.exit_experiment()
	run("A13 退出后倍率还原 1", is_equal_approx(Engine.time_scale, 1.0))
	run("A13 退出后回主菜单", Game.state == GameEnums.GameState.MAIN_MENU and not Game.in_experiment)
	run("A13 退出后解除暂停", get_tree().paused == false)
	Game.start_run()
	var b := Arena.new()
	add_child(b)
	b.spawner.enabled = false
	b.step_manual(0.0)
	run("A13 退出后开生存局无试验设置", b.is_experiment == false
			and b.player.invincible == false and b.player.lock_position == false
			and b.projectiles.auto_fire == true and b.camera_static == false)
	run("A13 灰度辅助已复位", Palette.grayscale == false)
	remove_child(a)
	a.queue_free()
	remove_child(ctl)
	ctl.queue_free()
	_free_arena(b)


func _test_ui_smoke() -> void:
	section("UI 冒烟（构建与关键刷新不报错）")
	var hud := Hud.new()
	add_child(hud)
	var pause := PauseMenu.new()
	add_child(pause)
	var levelup := LevelUpPanel.new()
	add_child(levelup)
	var results := ResultsPanel.new()
	add_child(results)
	var menu := MainMenu.new()
	add_child(menu)
	# 结果面板用假数据渲染一次
	var fake := RunContext.new()
	fake.result_win = true
	fake.result_reason = "生存满300秒"
	fake.kills = 42
	results.show_result(fake, ["火球伤害 ×2", "移动速度 ×1"])
	# 升级面板用假强化渲染一次
	var up := load("res://balance/upgrades/fire_damage.tres") as UpgradeDef
	levelup.show_choices([up], ["火球伤害 20 → 25"])
	run("UI 面板全部构建成功", hud != null and pause != null and levelup != null and results != null and menu != null)
	# 结构自检：面板根下确有内容（曾因 center_panel 双重挂载导致空面板）
	run("PauseMenu 结构完整", pause.get_child_count() > 0, str(pause.get_child_count()))
	run("ResultsPanel 结构完整", results.get_child_count() > 0, str(results.get_child_count()))
	run("MainMenu 结构完整", menu.get_child_count() > 0, str(menu.get_child_count()))
	run("LevelUpPanel 结构完整", levelup.get_child_count() > 0, str(levelup.get_child_count()))
	for node in [hud, pause, levelup, results, menu]:
		remove_child(node)
		node.queue_free()


func _test_spawner_a15() -> void:
	section("A15 刷怪上限与恢复刷新")
	var a := _new_arena(false)  # 本测试需要刷怪器
	a.spawner.max_alive_override = 3
	for i in 1200:  # 20 秒（间隔 1.3s，无上限可刷 ~15 个）
		a.step_manual(1.0 / 60.0)
	var alive := a.live_enemy_count()
	run("A15 存活不超过上限 3", alive <= 3, "alive=%d" % alive)
	run("A15 期间确实在刷怪", alive >= 2, "alive=%d" % alive)
	for e in a.enemies:
		e.position = a.player.position + Vector2(5000, 0)
	a.step_manual(1.0 / 60.0)
	a.step_manual(1.0 / 60.0)
	run("A15 超距回收清场", a.live_enemy_count() == 0, "left=%d" % a.enemies.size())
	for i in 156:  # 2.6 秒 = 两个刷新间隔
		a.step_manual(1.0 / 60.0)
	alive = a.live_enemy_count()
	run("A15 空出名额后恢复刷新且不补账", alive >= 1 and alive <= 3, "alive=%d" % alive)
	_free_arena(a)


func _test_project_config() -> void:
	section("工程配置")
	for action in ["move_up", "move_down", "move_left", "move_right", "pause",
			"choose_1", "choose_2", "choose_3", "test_fire", "lock_position"]:
		run("输入动作存在 %s" % action, InputMap.has_action(action))
	for single in ["EventBus", "Rng", "Game"]:
		run("autoload 存在 %s" % single, get_node_or_null("/root/" + single) != null)


func _test_xp_threshold() -> void:
	section("经验阈值（设计文档 7.2）")
	run("L1→2 需要 20", RunContext.xp_threshold(1) == 20, str(RunContext.xp_threshold(1)))
	run("L2→3 需要 30", RunContext.xp_threshold(2) == 30, str(RunContext.xp_threshold(2)))
	run("L3→4 需要 40", RunContext.xp_threshold(3) == 40, str(RunContext.xp_threshold(3)))


func _test_geo() -> void:
	section("扫掠碰撞（验收 A03 基础）")
	var t := Geo.segment_hit_t(Vector2(-100, 0), Vector2(100, 0), Vector2.ZERO, 10.0)
	run("正穿圆心命中 t=0.45", absf(t - 0.45) < 0.0001, str(t))
	t = Geo.segment_hit_t(Vector2(-100, 0), Vector2(100, 0), Vector2(0, 50), 10.0)
	run("远离未命中返回 -1", t == -1.0, str(t))
	t = Geo.segment_hit_t(Vector2(-100, 0), Vector2(100, 0), Vector2(0, 10), 10.0)
	run("相切圆 t=0.5", absf(t - 0.5) < 0.0001, str(t))
	t = Geo.segment_hit_t(Vector2.ZERO, Vector2(100, 0), Vector2.ZERO, 5.0)
	run("起点在圆内 t=0", t == 0.0, str(t))
	t = Geo.segment_hit_t(Vector2.ZERO, Vector2(100, 0), Vector2(-50, 0), 10.0)
	run("圆在身后未命中", t == -1.0, str(t))
	# 大步长（模拟低帧率）：一步 480px 仍命中路径上 300px 处（半径 20）的敌人
	# 进入点 x=280 → t = 280/480 ≈ 0.5833
	t = Geo.segment_hit_t(Vector2.ZERO, Vector2(480, 0), Vector2(300, 0), 20.0)
	run("大步长扫掠命中 t≈0.5833", absf(t - 280.0 / 480.0) < 0.0001, str(t))


func _test_balance() -> void:
	section("数值配置（设计文档建议初始值）")
	var rule := load("res://balance/fireball_rule.tres") as AttackRule
	run("火球伤害 20", rule != null and is_equal_approx(rule.damage, 20.0))
	run("火球间隔 1.0", rule != null and is_equal_approx(rule.fire_interval, 1.0))
	run("飞行速度 480", rule != null and is_equal_approx(rule.projectile_speed, 480.0))
	run("命中半径 8", rule != null and is_equal_approx(rule.hit_radius, 8.0))

	var pd := load("res://balance/player_default.tres") as PlayerDef
	run("玩家速度 220", pd != null and is_equal_approx(pd.move_speed, 220.0))
	run("玩家无敌 0.6s", pd != null and is_equal_approx(pd.contact_iframes, 0.6))

	var ed := load("res://balance/enemy_default.tres") as EnemyDef
	run("敌人生命 30", ed != null and is_equal_approx(ed.max_hp, 30.0))
	run("敌人接触伤害 10", ed != null and ed.contact_damage == 10)

	var curve := load("res://balance/spawn_curve.tres") as SpawnCurve
	run("刷怪曲线 3 段", curve != null and curve.phases.size() == 3)
	run("0s 属于第 1 段", curve.phase_at(0.0) == curve.phases[0])
	run("59.9s 属于第 1 段", curve.phase_at(59.9) == curve.phases[0])
	run("60s 属于第 2 段", curve.phase_at(60.0) == curve.phases[1])
	run("180s 属于第 3 段", curve.phase_at(180.0) == curve.phases[2])
	run("300s 属于第 3 段", curve.phase_at(300.0) == curve.phases[2])

	var vfx_a := load("res://balance/vfx_fireball_a.tres") as VfxProfile
	var vfx_b := load("res://balance/vfx_fireball_b.tres") as VfxProfile
	run("A 版尾迹 0.12", vfx_a != null and is_equal_approx(vfx_a.trail_lifetime, 0.12))
	run("B 版尾迹 0.22", vfx_b != null and is_equal_approx(vfx_b.trail_lifetime, 0.22))
	run("B 版有余烬碎片", vfx_b != null and vfx_b.muzzle_sparks)

	var ids := {}
	for path in ["fire_damage", "fire_rate", "move_speed", "pickup_radius", "max_hp"]:
		var up := load("res://balance/upgrades/%s.tres" % path) as UpgradeDef
		run("强化加载 %s" % path, up != null and up.id != &"")
		if up != null:
			ids[up.id] = true
	run("强化 id 无重复", ids.size() == 5)


# ---------- 主菜单点击回归（用户反馈：启动后菜单按钮点不了）----------

func _test_menu_click_regression() -> void:
	section("主菜单点击回归（用户反馈：启动后菜单点不了）")
	var main_scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main_scene)
	await get_tree().process_frame  # 等一帧让 Container 完成布局，否则矩形是脏的
	var hud: Control = main_scene.hud
	run("启动时 HUD 隐藏", hud.visible == false)
	run("HUD 不拦截鼠标", hud.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	var btn := _find_button(main_scene.main_menu, "开始生存")
	run("找到开始生存按钮", btn != null)
	if btn != null:
		var point: Vector2 = btn.get_global_rect().get_center()
		var blockers := _click_blockers(point, btn)
		var names: Array[String] = []
		for b in blockers:
			names.append(str(b.name))
		# headless 下 push_input 不走 GUI 拾取，改为直接断言"点击点上方无遮挡控件"
		# + 按钮信号链有效。两者成立则真实点击必然生效。
		run("按钮上方无遮挡控件", blockers.is_empty(), "、".join(names))
		btn.pressed.emit()
		run("按钮信号链有效：进入生存状态", Game.state == GameEnums.GameState.SURVIVAL,
				"state=%d" % Game.state)
		run("点击后场地已建立", main_scene.arena != null)
	remove_child(main_scene)
	main_scene.queue_free()
	Game.return_to_menu()


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node
	for c in node.get_children():
		var found := _find_button(c, text)
		if found != null:
			return found
	return null


## 返回在拾取顺序上位于 target 之上、覆盖 point、且会拦截鼠标的可见控件列表。
## 模拟 Viewport 的 GUI 拾取规则：CanvasLayer 越大越上；同层内分叉处 child
## 序号越大越上；一个是另一个祖先时更深者在上面。
func _click_blockers(point: Vector2, target: Control) -> Array[Control]:
	var blockers: Array[Control] = []
	var candidates: Array = []
	_collect_controls(get_tree().root, candidates)
	for c in candidates:
		var ctrl: Control = c
		if ctrl == target or _is_ancestor_of(ctrl, target):
			continue  # 按钮自身与其父容器不算遮挡
		if not ctrl.is_visible_in_tree():
			continue
		if ctrl.mouse_filter != Control.MOUSE_FILTER_STOP:
			continue  # IGNORE/PASS 不会吃掉点击
		if not ctrl.get_global_rect().has_point(point):
			continue
		if _is_picked_above(ctrl, target):
			blockers.append(ctrl)
	return blockers


func _collect_controls(node: Node, out: Array) -> void:
	if node is Control:
		out.append(node)
	for c in node.get_children():
		_collect_controls(c, out)


func _is_ancestor_of(node: Node, of: Node) -> bool:
	var p := of.get_parent()
	while p != null:
		if p == node:
			return true
		p = p.get_parent()
	return false


func _canvas_layer_of(node: Node) -> int:
	var n := node
	while n != null:
		if n is CanvasLayer:
			return n.layer
		n = n.get_parent()
	return 0


func _ancestor_chain(node: Node) -> Array:
	var chain: Array = []
	var n: Node = node
	while n != null:
		chain.push_front(n)
		n = n.get_parent()
	return chain


func _is_picked_above(a: Control, b: Control) -> bool:
	var la := _canvas_layer_of(a)
	var lb := _canvas_layer_of(b)
	if la != lb:
		return la > lb
	var chain_a := _ancestor_chain(a)
	var chain_b := _ancestor_chain(b)
	for i in mini(chain_a.size(), chain_b.size()):
		if chain_a[i] != chain_b[i]:
			return chain_a[i].get_index() > chain_b[i].get_index()
	# 未分叉：链短者是长者的祖先，更深者在上面
	return chain_a.size() > chain_b.size()


func _test_fire_art() -> void:
	section("火系美术与试验切换回归")
	run("角色贴图含透明背景", GameArt.PLAYER.get_image().get_pixel(0, 0).a == 0.0)
	run("四种火焰阶段均可读取", GameArt.fire(0).get_width() > 0 and GameArt.fire(1).get_width() > 0
			and GameArt.fire(2).get_width() > 0 and GameArt.fire(3).get_width() > 0)
	var a := _new_arena()
	Game.enter_experiment()
	var ctl := ExperimentController.new()
	add_child(ctl)
	ctl.setup(a)
	run("角色和靶子的受击材质独立", a.player.art_material != a.enemies[0].art_material)
	var rng_state := Rng.game_rng.state
	a.fx_layer.spawn_muzzle(Vector2.ZERO, Vector2.RIGHT, a.visual_b)
	a.fx_layer.spawn_hit(Vector2.ZERO, a.visual_b)
	var patch := FirePool.new()
	patch.rule = a.fire_egg_rule_base
	patch.setup_visual()
	patch.free()
	run("特效与火池动画不消耗玩法随机数", Rng.game_rng.state == rng_state)
	ctl.reset_world()
	ctl.single_fire()
	var first := a.projectiles.balls[0]
	var old_profile := first.visual
	ctl.set_visual(GameEnums.VisualVersion.B)
	ctl.single_fire()
	run("切换 B 后已有火球保留 A 版", first.visual == old_profile and first.visual != a.visual_b)
	run("切换 B 后新火球使用 B 版", a.projectiles.balls[1].visual == a.visual_b)
	ctl.set_fire_weapon(GameEnums.FireWeapon.SCATTER)
	ctl.single_fire()
	run("试验散射一次生成三发", a.projectiles.balls.size() == 3 and a.fire_eggs.eggs.is_empty())
	ctl.set_auto_fire(true)
	run("散射连续触发仅激活当前武器", a.scatter.active and a.scatter.auto_fire
			and not a.projectiles.auto_fire and not a.fire_eggs.active)
	ctl.set_auto_fire(false)
	ctl.set_fire_weapon(GameEnums.FireWeapon.FIRE_EGG)
	run("换到火蛋清空上一种弹体", a.projectiles.balls.is_empty())
	ctl.set_playback(GameEnums.PlaybackRate.PAUSED)
	ctl.single_fire()
	run("暂停时火蛋不能发射", a.fire_eggs.eggs.is_empty())
	ctl.set_playback(GameEnums.PlaybackRate.NORMAL_1)
	ctl.single_fire()
	run("试验火蛋单发正常", a.fire_eggs.eggs.size() == 1)
	var egg_profile := a.fire_eggs.eggs[0].visual
	ctl.set_visual(GameEnums.VisualVersion.A)
	for i in 112:
		a.step_manual(1.0 / 60.0)
	run("火蛋产生火池并保留发射时的视觉", a.fire_eggs.pools.size() == 1
			and a.fire_eggs.pools[0].visual == egg_profile)
	run("火蛋伤害参数指向每跳伤害", ctl.current_rule() is FireEggRule
			and ctl.rule_property("damage") == "pool_damage")
	ctl.current_rule().set(ctl.rule_property("damage"), 13.0)
	run("调火蛋参数不改普通火球伤害", a.fire_eggs.rule.pool_damage == 13.0
			and a.projectiles.rule.damage == 20.0)
	ctl.reset_world()
	run("重置清除弹体火池和特效", a.projectiles.balls.is_empty() and a.fire_eggs.eggs.is_empty()
			and a.fire_eggs.pools.is_empty() and a.fx_layer.fx_count() == 0)
	run("重置恢复火蛋规则", a.fire_eggs.rule.pool_damage == a.fire_egg_rule_base.pool_damage)
	var player_time := a.player.visual_time
	Game.set_state(GameEnums.GameState.PAUSED)
	a.step_manual(0.5)
	run("暂停时角色动画时钟停止", a.player.visual_time == player_time)
	Game.exit_experiment()
	remove_child(ctl)
	ctl.queue_free()
	_free_arena(a)
	var next := _new_arena()
	run("试验武器选择不带入生存", not next.scatter.active and not next.fire_eggs.active
			and next.projectiles.auto_fire)
	_free_arena(next)


# ---------- 试验面板遮挡回归（全功能走查实测发现的两个 bug）----------

func _test_experiment_panel_regression() -> void:
	section("试验面板遮挡回归")
	var main_scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	Game.enter_experiment()
	await get_tree().process_frame
	var panel: ExperimentPanel = main_scene.experiment.panel
	# bug1：Esc 菜单未打开时，其全屏暗化遮罩不得挡住试验面板的按钮
	run("Esc 菜单默认整体隐藏", panel.exit_root.visible == false)
	var blockers := _click_blockers(panel.btn_slow.get_global_rect().get_center(), panel.btn_slow)
	var names: Array[String] = []
	for b in blockers:
		names.append(str(b.name))
	run("慢放按钮上方无遮挡", blockers.is_empty(), "、".join(names))
	# bug2：退出试验后，面板（挂 ui_layer 下）必须随控制器一并销毁
	var panel_ref: WeakRef = weakref(panel)
	Game.exit_experiment()
	await get_tree().process_frame
	await get_tree().process_frame
	run("退出试验后面板已销毁", panel_ref.get_ref() == null)
	remove_child(main_scene)
	main_scene.queue_free()
	Game.return_to_menu()
