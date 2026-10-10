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
	finish()


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
