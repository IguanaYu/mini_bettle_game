class_name ExperimentPanel
extends Control
## 特效试验面板：预设 / 播放控制 / 触发 / A-B / 参数（规则与视觉分页）/ 辅助显示 / 计数。
## 可收起；收起后仍显示 暂停状态 · 倍率 · 无敌（设计文档 9.2 / 9.4）。

var ctl: ExperimentController

var root_panel: PanelContainer
var content: VBoxContainer
var mini_bar: HBoxContainer
var mini_label: Label

var preset_option: OptionButton
var count_spin: SpinBox
var cap_spin: SpinBox
var count_row: HBoxContainer
var cap_row: HBoxContainer
var btn_pause: Button
var btn_slow: Button
var btn_normal: Button
var auto_check: CheckButton
var btn_a: Button
var btn_b: Button
var invincible_check: CheckButton
var lock_check: CheckButton
var seed_spin: SpinBox
var rule_warn: Label
var dark_check: CheckButton
var gray_check: CheckButton
var collision_check: CheckButton
var counter_label: Label
var time_label: Label
var hint_label: Label
var exit_menu: PanelContainer

var rule_spins: Array = []   # [SpinBox, Callable(取值)]
var visual_spins: Array = []


func setup(controller: ExperimentController) -> void:
	ctl = controller
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	sync_from_controller()


func _build() -> void:
	root_panel = PanelContainer.new()
	root_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	root_panel.offset_left = -318
	root_panel.offset_right = -8
	root_panel.offset_top = 8
	root_panel.offset_bottom = 8
	add_child(root_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	root_panel.add_child(outer)

	var header := HBoxContainer.new()
	outer.add_child(header)
	var title := Ui.label("特效试验", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var collapse := Ui.button("收起", 70, 30)
	collapse.pressed.connect(func() -> void: _set_collapsed(true))
	header.add_child(collapse)

	mini_bar = HBoxContainer.new()
	mini_bar.visible = false
	mini_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mini_bar.offset_left = -330
	mini_bar.offset_right = -8
	mini_bar.offset_top = 8
	add_child(mini_bar)
	mini_label = Ui.label("", 14)
	mini_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mini_bar.add_child(mini_label)
	var expand := Ui.button("展开面板", 110, 30)
	expand.pressed.connect(func() -> void: _set_collapsed(false))
	mini_bar.add_child(expand)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 430)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

	# --- 预设 ---
	content.add_child(_section_label("场景预设"))
	preset_option = OptionButton.new()
	preset_option.add_item("单靶观察", GameEnums.ExperimentPreset.SINGLE_TARGET)
	preset_option.add_item("固定靶群", GameEnums.ExperimentPreset.TARGET_ARRAY)
	preset_option.add_item("实战追击", GameEnums.ExperimentPreset.LIVE_CHASE)
	preset_option.item_selected.connect(func(i: int) -> void:
		ctl.preset = i as GameEnums.ExperimentPreset
		ctl.apply_preset())
	content.add_child(preset_option)
	count_row = _row(content, "靶群数量")
	count_spin = _spin(count_row, 10, 50, 1, func() -> float: return float(ctl.target_count),
			func(v: float) -> void: ctl.target_count = int(v))
	cap_row = _row(content, "敌人上限")
	cap_spin = _spin(cap_row, 10, 200, 10, func() -> float: return float(ctl.live_cap),
			func(v: float) -> void:
				ctl.live_cap = int(v)
				if ctl.preset == GameEnums.ExperimentPreset.LIVE_CHASE:
					ctl.arena.spawner.max_alive_override = int(v))

	# --- 播放控制 ---
	content.add_child(_section_label("播放控制"))
	var pb_row := HBoxContainer.new()
	content.add_child(pb_row)
	btn_pause = Ui.button("暂停", 88, 34)
	btn_pause.pressed.connect(func() -> void:
		ctl.set_playback(GameEnums.PlaybackRate.PAUSED))
	pb_row.add_child(btn_pause)
	btn_slow = Ui.button("0.25×", 88, 34)
	btn_slow.pressed.connect(func() -> void:
		ctl.set_playback(GameEnums.PlaybackRate.SLOW_025))
	pb_row.add_child(btn_slow)
	btn_normal = Ui.button("1×", 88, 34)
	btn_normal.pressed.connect(func() -> void:
		ctl.set_playback(GameEnums.PlaybackRate.NORMAL_1))
	pb_row.add_child(btn_normal)

	# --- 触发 ---
	content.add_child(_section_label("攻击触发"))
	var fire_row := HBoxContainer.new()
	content.add_child(fire_row)
	var fire_btn := Ui.button("单次触发（空格）", 150, 34)
	fire_btn.pressed.connect(func() -> void: ctl.single_fire())
	fire_row.add_child(fire_btn)
	auto_check = CheckButton.new()
	auto_check.text = "连续自动触发"
	auto_check.toggled.connect(func(b: bool) -> void: ctl.set_auto_fire(b))
	fire_row.add_child(auto_check)

	# --- 视觉 A/B ---
	content.add_child(_section_label("火球视觉（只影响新生成）"))
	var vis_row := HBoxContainer.new()
	content.add_child(vis_row)
	btn_a = Ui.button("A 版（基线）", 140, 34)
	btn_a.pressed.connect(func() -> void: ctl.set_visual(GameEnums.VisualVersion.A))
	vis_row.add_child(btn_a)
	btn_b = Ui.button("B 版（翻卷）", 140, 34)
	btn_b.pressed.connect(func() -> void: ctl.set_visual(GameEnums.VisualVersion.B))
	vis_row.add_child(btn_b)

	# --- 试验条件 ---
	content.add_child(_section_label("试验条件"))
	var cond_row := HBoxContainer.new()
	content.add_child(cond_row)
	invincible_check = CheckButton.new()
	invincible_check.text = "无敌"
	invincible_check.toggled.connect(func(b: bool) -> void: ctl.set_invincible(b))
	cond_row.add_child(invincible_check)
	lock_check = CheckButton.new()
	lock_check.text = "锁定位置"
	lock_check.toggled.connect(func(b: bool) -> void: ctl.set_lock(b))
	cond_row.add_child(lock_check)
	var seed_row := _row(content, "随机种子")
	seed_spin = _spin(seed_row, 1, 2147483647, 1, func() -> float: return float(ctl.seed_value),
			func(v: float) -> void: ctl.seed_value = int(v))
	var reset_btn := Ui.button("重置（按当前种子）", 300, 36)
	reset_btn.pressed.connect(func() -> void: ctl.reset_world())
	content.add_child(reset_btn)

	# --- 参数（规则 / 视觉 分页）---
	content.add_child(_section_label("参数调整"))
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(296, 218)
	content.add_child(tabs)
	var rule_tab := VBoxContainer.new()
	rule_tab.name = "攻击规则"
	tabs.add_child(rule_tab)
	rule_warn = Ui.label("⚠ 本轮已改变玩法条件", 13)
	rule_warn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	rule_warn.visible = false
	rule_tab.add_child(rule_warn)
	_add_rule_spin(rule_tab, "伤害", 1, 500, 1, "damage")
	_add_rule_spin(rule_tab, "间隔 s", 0.05, 5.0, 0.05, "fire_interval")
	_add_rule_spin(rule_tab, "速度", 50, 2000, 10, "projectile_speed")
	_add_rule_spin(rule_tab, "寿命 s", 0.1, 6.0, 0.1, "lifetime")
	_add_rule_spin(rule_tab, "碰撞半径", 1, 50, 1, "hit_radius")
	var visual_tab := VBoxContainer.new()
	visual_tab.name = "视觉表现"
	tabs.add_child(visual_tab)
	_add_visual_spin(visual_tab, "主体半径", 2, 40, 1, "body_radius")
	_add_visual_spin(visual_tab, "尾迹寿命 s", 0.0, 1.0, 0.01, "trail_lifetime")
	_add_visual_spin(visual_tab, "命中时长 s", 0.02, 1.0, 0.01, "hit_flash_time")
	_add_visual_spin(visual_tab, "命中最大半径", 4, 80, 1, "hit_max_radius")
	_add_visual_spin(visual_tab, "余烬寿命 s", 0.0, 1.0, 0.01, "ember_lifetime")
	_add_visual_spin(visual_tab, "亮度", 0.2, 3.0, 0.05, "brightness")

	# --- 辅助显示 ---
	content.add_child(_section_label("可读性辅助"))
	var aux_row := HBoxContainer.new()
	content.add_child(aux_row)
	dark_check = _check(aux_row, "深色背景", func(b: bool) -> void:
		ctl.arena.ground.dark = b)
	gray_check = _check(aux_row, "灰度", func(b: bool) -> void:
		Palette.grayscale = b)
	collision_check = _check(aux_row, "碰撞显示", func(b: bool) -> void:
		ctl.arena.debug_draw.show_collisions = b)

	# --- 计数 ---
	content.add_child(_section_label("运行观察"))
	counter_label = Ui.label("", 13)
	content.add_child(counter_label)
	time_label = Ui.label("", 13)
	content.add_child(time_label)
	hint_label = Ui.label("", 13)
	hint_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	content.add_child(hint_label)

	# --- Esc 退出与重置菜单（设计文档 8.2）---
	exit_menu = Ui.center_panel(self)
	exit_menu.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	exit_menu.add_child(box)
	var et := Ui.label("试验暂停菜单", 20)
	et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(et)
	var b_resume := Ui.button("恢复播放 / 关闭")
	b_resume.pressed.connect(func() -> void:
		exit_menu.visible = false
		ctl.set_playback(GameEnums.PlaybackRate.NORMAL_1))
	box.add_child(b_resume)
	var b_reset := Ui.button("重置试验")
	b_reset.pressed.connect(func() -> void:
		exit_menu.visible = false
		ctl.reset_world())
	box.add_child(b_reset)
	var b_exit := Ui.button("退出试验")
	b_exit.pressed.connect(func() -> void: ctl.request_exit())
	box.add_child(b_exit)


# ---------- 构建辅助 ----------

func _section_label(text: String) -> Label:
	var l := Ui.label(text, 15)
	l.add_theme_color_override("font_color", Color(0.62, 0.78, 1.0))
	return l


func _row(parent: Node, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var l := Ui.label(text, 14)
	l.custom_minimum_size = Vector2(84, 0)
	row.add_child(l)
	return row


func _spin(parent: Node, minv: float, maxv: float, step: float,
		getter: Callable, setter: Callable) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = minv
	s.max_value = maxv
	s.step = step
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(v: float) -> void: setter.call(v))
	parent.add_child(s)
	s.set_value_no_signal(getter.call())
	return s


func _check(parent: Node, text: String, on_toggle: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = text
	c.toggled.connect(func(b: bool) -> void: on_toggle.call(b))
	parent.add_child(c)
	return c


func _add_rule_spin(parent: Node, label: String, minv: float, maxv: float, step: float, prop: String) -> void:
	var row := _row(parent, label)
	var s := _spin(row, minv, maxv, step,
		func() -> float: return float(ctl.arena.projectiles.rule.get(prop)),
		func(v: float) -> void:
			ctl.arena.projectiles.rule.set(prop, v)
			ctl.on_rule_changed())
	rule_spins.append(s)


func _add_visual_spin(parent: Node, label: String, minv: float, maxv: float, step: float, prop: String) -> void:
	var row := _row(parent, label)
	var s := _spin(row, minv, maxv, step,
		func() -> float: return float(ctl.current_profile().get(prop)),
		func(v: float) -> void: ctl.current_profile().set(prop, v))
	visual_spins.append(s)


# ---------- 状态同步 ----------

func sync_from_controller() -> void:
	preset_option.selected = ctl.preset
	count_row.visible = ctl.preset == GameEnums.ExperimentPreset.TARGET_ARRAY
	cap_row.visible = ctl.preset == GameEnums.ExperimentPreset.LIVE_CHASE
	count_spin.set_value_no_signal(ctl.target_count)
	cap_spin.set_value_no_signal(ctl.live_cap)
	auto_check.set_pressed_no_signal(ctl.auto_fire)
	invincible_check.set_pressed_no_signal(ctl.invincible)
	lock_check.set_pressed_no_signal(ctl.lock_position)
	seed_spin.set_value_no_signal(ctl.seed_value)
	rule_warn.visible = false
	sync_visual_buttons()
	sync_playback_buttons()
	refresh_spins()


func sync_visual_buttons() -> void:
	btn_a.modulate = Color(1, 1, 0.5) if ctl.visual_version == GameEnums.VisualVersion.A else Color(1, 1, 1)
	btn_b.modulate = Color(1, 1, 0.5) if ctl.visual_version == GameEnums.VisualVersion.B else Color(1, 1, 1)


func sync_playback_buttons() -> void:
	btn_pause.modulate = Color(1, 1, 0.5) if ctl.playback == GameEnums.PlaybackRate.PAUSED else Color(1, 1, 1)
	btn_slow.modulate = Color(1, 1, 0.5) if ctl.playback == GameEnums.PlaybackRate.SLOW_025 else Color(1, 1, 1)
	btn_normal.modulate = Color(1, 1, 0.5) if ctl.playback == GameEnums.PlaybackRate.NORMAL_1 else Color(1, 1, 1)


func refresh_spins() -> void:
	var rule: AttackRule = ctl.arena.projectiles.rule
	for s in rule_spins:
		var idx := rule_spins.find(s)
		# 顺序与 _add_rule_spin 注册顺序一致
		var props := ["damage", "fire_interval", "projectile_speed", "lifetime", "hit_radius"]
		s.set_value_no_signal(float(rule.get(props[idx])))
	var prof := ctl.current_profile()
	var vprops := ["body_radius", "trail_lifetime", "hit_flash_time", "hit_max_radius", "ember_lifetime", "brightness"]
	for s in visual_spins:
		var idx := visual_spins.find(s)
		s.set_value_no_signal(float(prof.get(vprops[idx])))


func mark_rule_changed() -> void:
	rule_warn.visible = true


func show_hint(text: String) -> void:
	hint_label.text = text


func update_counters() -> void:
	var a := ctl.arena
	var fps := Engine.get_frames_per_second()
	var frame_ms := 1000.0 / maxf(float(fps), 1.0)
	counter_label.text = "敌 %d · 弹 %d · 特效 %d · FPS %d（%.1f ms）" % [
		a.live_enemy_count(), a.projectiles.live_ball_count(), a.fx_layer.fx_count(), fps, frame_ms]
	time_label.text = "游戏时间 %s　真实时间 %s" % [_fmt_time(ctl.game_time), _fmt_time(ctl.real_time)]


func _fmt_time(t: float) -> String:
	return "%02d:%04.1f" % [int(t) / 60, fmod(t, 60.0)]


func _set_collapsed(collapsed: bool) -> void:
	root_panel.visible = not collapsed
	mini_bar.visible = collapsed
	if collapsed:
		# 收起后仍显示 暂停 / 倍率 / 无敌 状态（设计文档 9.4）
		var state := "暂停" if ctl.playback == GameEnums.PlaybackRate.PAUSED else \
				("0.25×" if ctl.playback == GameEnums.PlaybackRate.SLOW_025 else "1×")
		mini_label.text = "试验中 · %s%s" % [state, " · 无敌" if ctl.invincible else ""]


func _unhandled_input(event: InputEvent) -> void:
	if Game.state != GameEnums.GameState.EXPERIMENT or Game.ui_has_focus():
		return
	if event.is_action_pressed("pause"):
		exit_menu.visible = not exit_menu.visible
