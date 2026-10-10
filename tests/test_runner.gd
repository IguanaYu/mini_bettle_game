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
