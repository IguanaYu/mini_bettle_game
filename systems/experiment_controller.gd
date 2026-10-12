class_name ExperimentController
extends Node
## 试验模式控制器：预设、播放控制、单次/连续触发、参数覆盖、重置（设计文档 9 章）。
## 本节点 PROCESS_MODE_ALWAYS（面板暂停时仍可用）；世界推进仍由 Arena（PAUSABLE）承担。

signal exit_requested

var arena: Arena
var panel: ExperimentPanel
var preset: GameEnums.ExperimentPreset = GameEnums.ExperimentPreset.SINGLE_TARGET
var playback: GameEnums.PlaybackRate = GameEnums.PlaybackRate.NORMAL_1
var invincible := false
var lock_position := false
var visual_version: GameEnums.VisualVersion = GameEnums.VisualVersion.A
var fire_weapon: GameEnums.FireWeapon = GameEnums.FireWeapon.FIREBALL
var auto_fire := false
var seed_value := 20261011
var target_count := 12   # 固定靶群数量（10~50，设计文档 9.1）
var live_cap := 60       # 实战追击敌人上限
var game_time := 0.0     # 游戏时间（受慢放缩放）
var real_time := 0.0     # 真实经过时间


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(a: Arena) -> void:
	arena = a
	arena.is_experiment = true
	arena.camera_static = true      # 试验固定镜头，靶子始终在画面内
	arena.player.position = Vector2.ZERO
	arena.projectiles.auto_fire = false  # 试验默认手动触发
	apply_preset()


func build_panel(parent: Node) -> void:
	panel = ExperimentPanel.new()
	parent.add_child(panel)
	panel.setup(self)


func _process(delta: float) -> void:
	if Game.state != GameEnums.GameState.EXPERIMENT:
		return
	real_time += delta
	if world_running():
		game_time += delta  # _process 的 delta 已被 time_scale 缩放
	if panel != null:
		panel.update_counters()


func world_running() -> bool:
	return Game.state == GameEnums.GameState.EXPERIMENT and not get_tree().paused


# ---------- 预设与重置 ----------

func apply_preset() -> void:
	reset_world()


func reset_world() -> void:
	## 重置：清场 + 种子 + 参数还原 + 重建预设（设计文档 9.3）
	arena.clear_world()
	Rng.reseed(seed_value)
	# 攻击规则从基础配置重建（面板改过的副本作废）
	arena.projectiles.set_rule(arena.fireball_rule_base.duplicate())
	arena.scatter.rule = arena.scatter_rule_base.duplicate()
	arena.scatter.cooldown = 0.0
	arena.fire_eggs.rule = arena.fire_egg_rule_base.duplicate()
	_sync_weapons()
	arena.restore_visuals()
	_set_visual(visual_version)
	# 固定发射点：玩家回原点
	arena.player.position = Vector2.ZERO
	arena.world_time = 0.0
	game_time = 0.0
	arena.spawner.reset_clock()
	arena.spawner.max_alive_override = live_cap if preset == GameEnums.ExperimentPreset.LIVE_CHASE else -1
	arena.spawner.enabled = preset == GameEnums.ExperimentPreset.LIVE_CHASE
	_build_preset()
	if panel != null:
		panel.sync_from_controller()


func _build_preset() -> void:
	## 给木靶贴图留出边缘余量，避免靶群与墙或右侧面板重叠。
	match preset:
		GameEnums.ExperimentPreset.SINGLE_TARGET:
			arena.spawn_target(Vector2(280, 0), true)
		GameEnums.ExperimentPreset.TARGET_ARRAY:
			for i in target_count:
				var ang := TAU * float(i) / float(target_count)
				arena.spawn_target(Vector2(270, 0).rotated(ang), true)
		GameEnums.ExperimentPreset.LIVE_CHASE:
			pass  # spawner 已开启


# ---------- 播放控制（设计文档 9.2）----------

func set_playback(p: GameEnums.PlaybackRate) -> void:
	playback = p
	match p:
		GameEnums.PlaybackRate.PAUSED:
			get_tree().paused = true
		GameEnums.PlaybackRate.SLOW_025:
			get_tree().paused = false
			Engine.time_scale = 0.25
		GameEnums.PlaybackRate.NORMAL_1:
			get_tree().paused = false
			Engine.time_scale = 1.0
	if panel != null:
		panel.sync_playback_buttons()


# ---------- 触发（设计文档 8.2 / 9.2）----------

func single_fire() -> void:
	## 世界运行时才触发生效；暂停时提示先恢复或开慢放
	if not world_running():
		if panel != null:
			panel.show_hint("世界暂停中：先恢复播放或开启慢放再触发")
		return
	var t := arena.projectiles.find_target()
	match fire_weapon:
		GameEnums.FireWeapon.FIREBALL:
			if t != null:
				arena.projectiles.fire_at(t)
			else:
				arena.projectiles.fire_forward()
		GameEnums.FireWeapon.SCATTER:
			arena.scatter.fire_volley(t)
		GameEnums.FireWeapon.FIRE_EGG:
			if t != null:
				arena.fire_eggs.fire_at(t)
			else:
				arena.fire_eggs.fire_dir(Vector2.RIGHT)


func set_auto_fire(b: bool) -> void:
	auto_fire = b
	_sync_weapons()


func set_fire_weapon(weapon: GameEnums.FireWeapon) -> void:
	fire_weapon = weapon
	reset_world()


func _sync_weapons() -> void:
	arena.projectiles.auto_fire = auto_fire and fire_weapon == GameEnums.FireWeapon.FIREBALL
	arena.scatter.active = fire_weapon == GameEnums.FireWeapon.SCATTER
	arena.scatter.auto_fire = auto_fire
	arena.fire_eggs.active = fire_weapon == GameEnums.FireWeapon.FIRE_EGG
	arena.fire_eggs.auto_fire = auto_fire


func current_rule() -> Resource:
	match fire_weapon:
		GameEnums.FireWeapon.SCATTER:
			return arena.scatter.rule
		GameEnums.FireWeapon.FIRE_EGG:
			return arena.fire_eggs.rule
	return arena.projectiles.rule


func rule_property(prop: String) -> String:
	return "pool_damage" if prop == "damage" and fire_weapon == GameEnums.FireWeapon.FIRE_EGG else prop


# ---------- 视觉与试验条件 ----------

func set_visual(v: GameEnums.VisualVersion) -> void:
	_set_visual(v)
	if panel != null:
		panel.sync_from_controller()


func _set_visual(v: GameEnums.VisualVersion) -> void:
	## A/B 切换只影响之后生成的攻击（设计文档 9.3）
	visual_version = v
	arena.projectiles.current_visual = arena.visual_a if v == GameEnums.VisualVersion.A else arena.visual_b


func current_profile() -> VfxProfile:
	return arena.visual_a if visual_version == GameEnums.VisualVersion.A else arena.visual_b


func set_invincible(b: bool) -> void:
	invincible = b
	arena.player.invincible = b


func set_lock(b: bool) -> void:
	lock_position = b
	arena.player.lock_position = b


func on_rule_changed() -> void:
	## 面板改规则参数时标明"本轮已改变玩法条件"（设计文档 9.2）
	if panel != null:
		panel.mark_rule_changed()


func request_exit() -> void:
	exit_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if Game.state != GameEnums.GameState.EXPERIMENT:
		return
	if Game.ui_has_focus():
		return
	if event.is_action_pressed("test_fire"):
		single_fire()
	elif event.is_action_pressed("lock_position"):
		set_lock(not lock_position)
		if panel != null:
			panel.sync_from_controller()
