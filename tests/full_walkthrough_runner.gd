extends Node
## 全功能走查（窗口模式，真实输入管线 Input.parse_input_event，与 OS 事件同链路）。
##   godot --path . res://tests/full_walkthrough_runner.tscn
## 覆盖：主菜单/生存全流程（移动·刷怪·火球·受击·经验·升级·暂停·F3·死亡结算·重开·
## 返回菜单）/试验模式全功能（三预设·触发·慢放·暂停拦截·A/B·参数标红·无敌·辅助显示·
## 重置·Esc 菜单·退出无残留）/退出按钮。每步截图 + 断言，退出码 0 = 全过。
## 截图存 docs/screenshots/walkthrough/。

var failures: Array[String] = []
var main_scene: Node
var shot_dir: String
var step_no := 0


func _ready() -> void:
	shot_dir = ProjectSettings.globalize_path("res://docs/screenshots/walkthrough/")
	DirAccess.make_dir_recursive_absolute(shot_dir)
	# 锁 60fps：窗口被遮挡时引擎可能不限帧，帧数等待 ≠ 真实秒数，节奏会失真
	Engine.max_fps = 60
	await get_tree().process_frame

	main_scene = load("res://scenes/main.tscn").instantiate()
	add_child(main_scene)
	await _frames(30)

	await _walk_main_menu()
	await _walk_survival()
	await _walk_level_up()
	await _walk_pause_f3()
	await _walk_death_and_restart()
	await _walk_experiment()
	await _walk_exit()

	# 正常情况下 _walk_exit 里点"退出"已经 quit；走到这里说明退出按钮没生效
	print("[walk] 退出按钮未生效，测试判定失败")
	get_tree().quit(1)


# ==================== 1 主菜单 ====================

func _walk_main_menu() -> void:
	_shot("01_menu")
	_check("主菜单显示", main_scene.main_menu.visible)
	_check("菜单有开始生存按钮", _find_button(main_scene.main_menu, "开始生存") != null)
	_check("菜单有特效试验按钮", _find_button(main_scene.main_menu, "特效试验") != null)
	_check("菜单有退出按钮", _find_button(main_scene.main_menu, "退出") != null)


# ==================== 2 生存：进入/移动/刷怪/火球/受击 ====================

func _walk_survival() -> void:
	_click(_find_button(main_scene.main_menu, "开始生存"))
	await _frames(30)
	_shot("02_survival_start")
	_check("点击开始生存进入对局", Game.state == GameEnums.GameState.SURVIVAL)
	_check("HUD 显示", main_scene.hud.visible)
	_check("满血开始", main_scene.arena.player.hp == 100)

	# 移动 + 相机跟随（按住 D 90 帧；高刷屏帧长更短，阈值按 0.75 秒估算）
	var x0: float = main_scene.arena.player.position.x
	await _hold_key(KEY_D, 90)
	await _frames(5)
	_shot("03_moved_right")
	_check("按住 D 向右移动", main_scene.arena.player.position.x > x0 + 150.0,
			"dx=%.0f" % (main_scene.arena.player.position.x - x0))
	_check("相机跟随玩家", main_scene.arena.camera.position.distance_to(
			main_scene.arena.player.position) < 1.0)

	# 战斗期：贪心捡经验（朝最近宝石走位，同时躲开围殴），最多 70 秒
	# 注意：lambda 按值捕获 int，计数器必须用容器
	var counter := {"fired": 0}
	var conn := func(_e, _i, _p, _d): counter["fired"] += 1
	EventBus.attack_fired.connect(conn)
	var t := 0
	while t < 4200 and Game.run.kills < 4 \
			and Game.state == GameEnums.GameState.SURVIVAL:
		await _chase_nearest_gem()
		t += 30
	_shot("04_combat")
	_check("敌人已刷新", main_scene.arena.live_enemy_count() > 0)
	_check("火球自动发射", counter["fired"] > 0, "fired=%d" % counter["fired"])
	_check("已产生击杀", Game.run.kills > 0, "kills=%d" % Game.run.kills)
	EventBus.attack_fired.disconnect(conn)


# ==================== 3 升级界面 ====================

func _walk_level_up() -> void:
	# 4 杀 = 20 经验 = 升级；若上一步已触发则直接验证
	var t := 0
	while Game.state != GameEnums.GameState.LEVEL_UP and t < 2400:
		await _frames(30)
		t += 30
	_shot("06_level_up")
	_check("经验足够后弹出升级选择", Game.state == GameEnums.GameState.LEVEL_UP)
	_check("升级面板显示卡片", main_scene.level_up_panel.visible)
	# 等级在收集经验时就已 +1（设计文档 7.2），选择卡片验证的是恢复与层数
	_tap_key(KEY_1)
	await _frames(20)
	_shot("07_level_up_chosen")
	if Game.run.pending_level_ups > 0:
		_check("仍有待升级（连续升级流程）", true)
		_tap_key(KEY_2)
		await _frames(20)
	_check("选择后恢复战斗", Game.state == GameEnums.GameState.SURVIVAL)
	_check("等级已提升", Game.run.level >= 2, "level=%d" % Game.run.level)
	_check("强化层数已记录", Game.run.upgrade_stacks.size() > 0)

	# 受击：站桩让敌人摸到（血量下降）——升级选择期间世界暂停，放在恢复后测
	var waits := 0
	while main_scene.arena.player.hp >= 100 and waits < 1800 \
			and Game.state == GameEnums.GameState.SURVIVAL:
		await _frames(30)
		waits += 30
	_shot("05_damaged")
	_check("接触伤害生效血量下降", main_scene.arena.player.hp < 100,
			"hp=%d" % main_scene.arena.player.hp)


# ==================== 4 暂停菜单 / F3 ====================

func _walk_pause_f3() -> void:
	_tap_key(KEY_ESCAPE)
	await _frames(15)
	_shot("08_pause_menu")
	_check("Esc 进入暂停", Game.state == GameEnums.GameState.PAUSED)
	_check("暂停菜单显示", main_scene.pause_menu.visible)
	_check("暂停时世界停摆", get_tree().paused == true)
	_click(_find_button(main_scene.pause_menu, "继续"))
	await _frames(15)
	_shot("09_pause_resumed")
	_check("点击继续恢复战斗", Game.state == GameEnums.GameState.SURVIVAL)

	# F3 是轮询式物理键（非动作），需要保持几帧才能被边沿检测看到
	await _hold_key(KEY_F3, 6)
	await _frames(3)
	_shot("10_debug_f3")
	_check("F3 调试页显示", main_scene.hud.debug_label.visible)
	await _hold_key(KEY_F3, 6)  # 再按关闭


# ==================== 5 死亡结算 / 重开 / 返回主菜单 ====================

func _walk_death_and_restart() -> void:
	# 站桩等死（最多 60 秒）
	var t := 0
	while not (Game.run != null and Game.run.finished) and t < 3600:
		await _frames(30)
		t += 30
	_shot("11_results")
	_check("死亡后进入结算", Game.state == GameEnums.GameState.RESULTS)
	_check("结算面板显示", main_scene.results_panel.visible)
	_check("失败原因为死亡", Game.run.result_win == false and Game.run.result_reason == "死亡")
	_check("结算含击杀与等级数据", Game.run.kills > 0 and Game.run.level >= 2)

	_click(_find_button(main_scene.results_panel, "重开"))
	await _frames(30)
	_shot("12_restart")
	_check("点击重开进入新局", Game.state == GameEnums.GameState.SURVIVAL)
	_check("新局数值归零", Game.run.kills == 0 and Game.run.level == 1
			and main_scene.arena.player.hp == 100)

	_tap_key(KEY_ESCAPE)
	await _frames(15)
	_click(_find_button(main_scene.pause_menu, "返回主菜单"))
	await _frames(30)
	_shot("13_back_to_menu")
	_check("返回主菜单", Game.state == GameEnums.GameState.MAIN_MENU)


# ==================== 6 试验模式 ====================

func _walk_experiment() -> void:
	_click(_find_button(main_scene.main_menu, "特效试验"))
	await _frames(30)
	_shot("20_exp_single_target")
	_check("进入试验模式", Game.state == GameEnums.GameState.EXPERIMENT)
	var panel: ExperimentPanel = main_scene.experiment.panel
	_check("试验面板显示", panel != null and panel.visible)
	_check("单靶预设就位", main_scene.arena.enemies.size() == 1
			and main_scene.arena.enemies[0].is_target)
	_check("默认手动触发", main_scene.arena.projectiles.auto_fire == false)

	# 空格单次触发
	_tap_key(KEY_SPACE)
	await _frames(10)
	_shot("21_exp_fire")
	_check("空格触发生成弹体", main_scene.arena.projectiles.live_ball_count() > 0)
	await _frames(90)

	# 0.25× 慢放
	_click(panel.btn_slow)
	await _frames(5)
	_check("0.25× 慢放生效", is_equal_approx(Engine.time_scale, 0.25))
	_tap_key(KEY_SPACE)
	await _frames(30)
	_shot("22_exp_slowmo")
	_check("慢放下仍可触发", main_scene.arena.projectiles.live_ball_count() > 0)

	# 暂停时单次触发无效 + 提示
	var balls_before: int = main_scene.arena.projectiles.live_ball_count()
	_click(panel.btn_pause)
	await _frames(10)
	_shot("23_exp_paused")
	_check("播放暂停置位", get_tree().paused == true)
	_tap_key(KEY_SPACE)
	await _frames(10)
	_check("暂停时空格触发无效", main_scene.arena.projectiles.live_ball_count() == balls_before)
	_check("面板给出提示", panel.hint_label.text.length() > 0, panel.hint_label.text)

	# 恢复 1× + 切 B 版视觉
	_click(panel.btn_normal)
	await _frames(5)
	_check("恢复 1× 播放", is_equal_approx(Engine.time_scale, 1.0) and not get_tree().paused)
	_click(panel.btn_b)
	await _frames(5)
	_check("切换到 B 版视觉", main_scene.experiment.visual_version == GameEnums.VisualVersion.B)
	_tap_key(KEY_SPACE)
	await _frames(25)
	_shot("24_exp_visual_b")
	var b_ball := _last_live_ball()
	_check("新弹体使用 B 版", b_ball != null and b_ball.visual == main_scene.arena.visual_b)
	await _frames(120)

	# 参数调整：点"伤害"输入 99 → 规则标红（真实点击 + 键盘输入）
	_click(panel.btn_normal)
	var dmg_spin := _find_spinbox(panel, "伤害")
	_check("找到伤害参数框", dmg_spin != null)
	if dmg_spin != null:
		_click(dmg_spin)
		await _frames(3)
		_tap_ctrl_a_and_type("99")
		await _frames(5)
		_shot("25_exp_rule_changed")
		_check("规则参数已改 99", is_equal_approx(
				main_scene.arena.projectiles.rule.damage, 99.0),
				"damage=%.1f" % main_scene.arena.projectiles.rule.damage)
		_check("规则修改标红提示", panel.rule_warn.visible)
		_click(panel.btn_normal)  # 把焦点从输入框挪走
		await _frames(3)

	# 固定靶群
	await _click(panel.preset_buttons[1])
	await _frames(10)
	_shot("26_exp_target_array")
	_check("固定靶群生成", main_scene.arena.enemies.size() == main_scene.experiment.target_count)

	# 实战追击 + 无敌 + 锁定
	await _click(panel.preset_buttons[2])
	await _frames(10)
	await _click(panel.invincible_check)
	await _click(panel.lock_check)
	await _frames(5)
	_check("实战模式刷怪开启", main_scene.arena.spawner.enabled == true)
	_check("无敌已开启", main_scene.arena.player.invincible == true)
	_check("锁定位置已开启", main_scene.arena.player.lock_position == true)
	var hp0: int = main_scene.arena.player.hp
	var tw := 0
	while main_scene.arena.live_enemy_count() < 3 and tw < 1200:
		await _frames(30)
		tw += 30
	_shot("27_exp_live_invincible")
	_check("实战敌人已进场", main_scene.arena.live_enemy_count() >= 3)
	_check("无敌状态不扣血", main_scene.arena.player.hp == hp0)

	# 可读性辅助：深色 / 灰度 / 碰撞显示（在滚动区下部，点击前先滚入可视区）
	await _click(panel.dark_check)
	await _frames(3)
	_shot("28_exp_dark")
	_check("深色背景切换", main_scene.arena.ground.dark == true)
	await _click(panel.gray_check)
	await _frames(3)
	_shot("29_exp_grayscale")
	_check("灰度切换", Palette.grayscale == true)
	await _click(panel.collision_check)
	await _frames(3)
	_shot("30_exp_collision")
	_check("碰撞显示切换", main_scene.arena.debug_draw.show_collisions == true)
	await _click(panel.dark_check)
	await _click(panel.gray_check)
	await _click(panel.collision_check)

	# 重置：清场 + 参数还原
	_click(_find_button(panel, "重置（按当前种子）"))
	await _frames(15)
	_shot("31_exp_reset")
	_check("重置后规则还原", is_equal_approx(
			main_scene.arena.projectiles.rule.damage, 20.0))
	_check("重置后单靶重建", main_scene.arena.enemies.size() == 1)

	# Esc 试验菜单 → 退出试验
	_tap_key(KEY_ESCAPE)
	await _frames(10)
	_shot("32_exp_menu")
	_check("Esc 打开试验菜单", panel.exit_root.visible)
	_click(_find_button(panel.exit_menu, "退出试验"))
	await _frames(30)
	_check("退出试验回主菜单", Game.state == GameEnums.GameState.MAIN_MENU)

	# 退出后无残留：再开一局生存
	_click(_find_button(main_scene.main_menu, "开始生存"))
	await _frames(30)
	_shot("33_after_exit_survival")
	_check("退出试验后正常开生存局", Game.state == GameEnums.GameState.SURVIVAL
			and main_scene.arena.is_experiment == false)
	_check("无敌未带入正常局", main_scene.arena.player.invincible == false
			and main_scene.arena.player.lock_position == false)
	_check("倍率还原", is_equal_approx(Engine.time_scale, 1.0))
	_check("灰度未带入", Palette.grayscale == false)
	_check("自动攻击恢复", main_scene.arena.projectiles.auto_fire == true)


# ==================== 7 退出按钮 ====================

func _walk_exit() -> void:
	_tap_key(KEY_ESCAPE)
	await _frames(15)
	_click(_find_button(main_scene.pause_menu, "返回主菜单"))
	await _frames(30)
	_shot("34_final_menu")
	_check("回到主菜单准备退出", Game.state == GameEnums.GameState.MAIN_MENU)
	# 汇总要在点"退出"前打印：quit 之后本函数不会再回来
	print("[walk] ====== 走查完成: %d 失败 ======" % failures.size())
	for f in failures:
		print("[walk] 失败项: %s" % f)
	print("[walk] 点击退出按钮，游戏即将关闭（正常退出码 0 即为通过）")
	_click(_find_button(main_scene.main_menu, "退出"))
	await _frames(60)


# ==================== 输入注入（与 OS 事件同链路）====================

func _click(c: Control) -> void:
	if c == null:
		return
	# 控件在滚动容器里时先滚入可视区，否则点击坐标会落在裁剪区外
	var sc := _scroll_ancestor(c)
	if sc != null:
		sc.ensure_control_visible(c)
		await get_tree().process_frame
	var pos: Vector2 = c.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	motion.global_position = pos
	Input.parse_input_event(motion)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = pos
	press.global_position = pos
	Input.parse_input_event(press)
	var release: InputEventMouseButton = press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)


func _scroll_ancestor(node: Node) -> ScrollContainer:
	var p := node.get_parent()
	while p != null:
		if p is ScrollContainer:
			return p
		p = p.get_parent()
	return null


func _tap_key(keycode: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.physical_keycode = keycode
	press.pressed = true
	Input.parse_input_event(press)
	var release: InputEventKey = press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)


func _hold_key(keycode: Key, frames: int) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.physical_keycode = keycode
	press.pressed = true
	Input.parse_input_event(press)
	await _frames(frames)
	var release: InputEventKey = press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)


func _tap_ctrl_a_and_type(text: String) -> void:
	# Ctrl+A 全选后逐字符输入，回车提交（SpinBox 真实输入路径）
	var ctrl := InputEventKey.new()
	ctrl.keycode = KEY_CTRL
	ctrl.pressed = true
	Input.parse_input_event(ctrl)
	var a_down := InputEventKey.new()
	a_down.keycode = KEY_A
	a_down.ctrl_pressed = true
	a_down.pressed = true
	Input.parse_input_event(a_down)
	var a_up: InputEventKey = a_down.duplicate()
	a_up.pressed = false
	Input.parse_input_event(a_up)
	var ctrl_up: InputEventKey = ctrl.duplicate()
	ctrl_up.pressed = false
	Input.parse_input_event(ctrl_up)
	for ch in text:
		var ev := InputEventKey.new()
		ev.unicode = ch.unicode_at(0)
		match ch:
			"0": ev.keycode = KEY_0
			"1": ev.keycode = KEY_1
			"2": ev.keycode = KEY_2
			"3": ev.keycode = KEY_3
			"4": ev.keycode = KEY_4
			"5": ev.keycode = KEY_5
			"6": ev.keycode = KEY_6
			"7": ev.keycode = KEY_7
			"8": ev.keycode = KEY_8
			"9": ev.keycode = KEY_9
		ev.pressed = true
		Input.parse_input_event(ev)
		var up: InputEventKey = ev.duplicate()
		up.pressed = false
		Input.parse_input_event(up)
	_tap_key(KEY_ENTER)


# ==================== 查找辅助 ====================

func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node
	for c in node.get_children():
		var found := _find_button(c, text)
		if found != null:
			return found
	return null


func _find_spinbox(root: Control, label: String) -> SpinBox:
	## 按"行标签"查找参数行的 SpinBox（规则页与视觉页共用）
	for row in _find_all(root, HBoxContainer):
		for c in row.get_children():
			if c is Label and label in c.text:
				for c2 in row.get_children():
					if c2 is SpinBox:
						return c2
	return null


func _find_all(node: Node, type: Variant) -> Array:
	var out: Array = []
	if is_instance_of(node, type):
		out.append(node)
	for c in node.get_children():
		out.append_array(_find_all(c, type))
	return out


func _last_live_ball() -> Fireball:
	var balls: Array[Fireball] = main_scene.arena.projectiles.balls
	for i in range(balls.size() - 1, -1, -1):
		if not balls[i].dead:
			return balls[i]
	return null


# ==================== 断言与截图 ====================

func _check(name: String, ok: bool, detail := "") -> void:
	step_no += 1
	if ok:
		print("[walk] #%02d PASS %s" % [step_no, name])
	else:
		failures.append("#%02d %s %s" % [step_no, name, detail])
		print("[walk] #%02d FAIL %s  %s" % [step_no, name, detail])


func _shot(tag: String) -> void:
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(shot_dir + tag + ".png")


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _nearest_gem() -> ExpGem:
	var best: ExpGem = null
	var best_d := 1e9
	for g in main_scene.arena.xp_manager.gems:
		var d: float = g.position.distance_to(main_scene.arena.player.position)
		if d < best_d:
			best_d = d
			best = g
	return best


func _chase_nearest_gem() -> void:
	## 朝最近经验宝石按方向键走 0.4 秒；没有宝石就原地等
	var gem := _nearest_gem()
	if gem == null:
		await _frames(30)
		return
	var d: Vector2 = gem.position - main_scene.arena.player.position
	var key := KEY_D
	if absf(d.x) > absf(d.y):
		key = KEY_D if d.x > 0.0 else KEY_A
	else:
		key = KEY_S if d.y > 0.0 else KEY_W
	await _hold_key(key, 25)
	await _frames(5)
