class_name Hud
extends Control
## 生存界面信息：生命/等级/经验/倒计时/击杀/火球摘要（设计文档 8.1）。信息贴屏幕边缘。

var hp_bar: ProgressBar
var hp_label: Label
var level_label: Label
var xp_bar: ProgressBar
var time_label: Label
var kill_label: Label
var fire_label: Label
var debug_label: Label

var arena: Arena
var debug_visible := false
var _f3_held := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 左上：生命 + 等级/经验
	var tl := VBoxContainer.new()
	tl.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tl.offset_left = 12
	tl.offset_top = 10
	tl.add_theme_constant_override("separation", 4)
	add_child(tl)
	hp_bar = ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(220, 18)
	tl.add_child(hp_bar)
	hp_label = Ui.label("100 / 100")
	tl.add_child(hp_label)
	level_label = Ui.label("等级 1")
	tl.add_child(level_label)
	xp_bar = ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.custom_minimum_size = Vector2(220, 8)
	xp_bar.modulate = Color(0.4, 0.8, 1.0)
	tl.add_child(xp_bar)

	# 右上：剩余时间
	time_label = Ui.label("04:59", 26)
	time_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	time_label.offset_left = -140
	time_label.offset_right = -12
	time_label.offset_top = 8
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(time_label)

	# 右下：击杀数 + 调试页（F3）
	var br := VBoxContainer.new()
	br.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	br.offset_left = -220
	br.offset_right = -12
	br.offset_top = -80
	br.offset_bottom = -10
	br.alignment = BoxContainer.ALIGNMENT_END
	add_child(br)
	kill_label = Ui.label("击杀 0")
	kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	br.add_child(kill_label)
	debug_label = Ui.label("", 13)
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	debug_label.visible = false
	br.add_child(debug_label)

	# 左下：火球摘要
	fire_label = Ui.label("火球 伤20 · 间隔1.00s", 14)
	fire_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	fire_label.offset_left = 12
	fire_label.offset_bottom = -10
	fire_label.offset_top = -34
	add_child(fire_label)

	EventBus.player_damaged.connect(func(_a, _h): refresh_hp())
	EventBus.xp_collected.connect(func(_v, _t, _l): refresh_xp())
	EventBus.level_up_pending.connect(func(_p): refresh_xp())
	EventBus.upgrade_chosen.connect(func(_id, _s, _sum): refresh_fire())
	refresh_all()


func bind(a: Arena) -> void:
	arena = a
	refresh_all()


func refresh_all() -> void:
	refresh_hp()
	refresh_xp()
	refresh_fire()
	if arena != null:
		kill_label.text = "击杀 %d" % Game.run.kills


func refresh_hp() -> void:
	if arena == null:
		return
	hp_bar.max_value = arena.player.max_hp
	hp_bar.value = arena.player.hp
	hp_label.text = "%d / %d" % [arena.player.hp, arena.player.max_hp]


func refresh_xp() -> void:
	var run := Game.run
	if run == null:
		return
	level_label.text = "等级 %d" % run.level
	xp_bar.max_value = RunContext.xp_threshold(run.level)
	xp_bar.value = run.xp


func refresh_fire() -> void:
	if arena == null:
		return
	var rule := arena.projectiles.rule
	fire_label.text = "火球 伤%d · 间隔%.2fs" % [int(round(rule.damage)), rule.fire_interval]


func _process(_delta: float) -> void:
	var run := Game.run
	if run != null:
		var left := maxf(0.0, Game.RUN_DURATION - run.elapsed)
		time_label.text = "%02d:%02d" % [int(left) / 60, int(left) % 60]
		kill_label.text = "击杀 %d" % run.kills
	# F3 调试页（开发方案 1.10）
	var f3 := Input.is_physical_key_pressed(KEY_F3)
	if f3 and not _f3_held:
		debug_visible = not debug_visible
		debug_label.visible = debug_visible
	_f3_held = f3
	if debug_visible and arena != null:
		var fx_n := 0
		if arena.fx_layer != null:
			fx_n = arena.fx_layer.fx_count()
		debug_label.text = "敌 %d · 弹 %d · 特效 %d · FPS %d" % [
			arena.live_enemy_count(), arena.projectiles.live_ball_count(), fx_n,
			Engine.get_frames_per_second()]
