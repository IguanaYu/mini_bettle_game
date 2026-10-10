extends Node
## 根场景：界面层与场地（Arena）的组装、按状态切换显隐（开发方案 4.1）。
## 升级流程：level_up_pending → LEVEL_UP 状态 → 本脚本驱动卡片显示与连续选择。

var ui_layer: CanvasLayer
var main_menu: MainMenu
var hud: Hud
var pause_menu: PauseMenu
var level_up_panel: LevelUpPanel
var results_panel: ResultsPanel
var sfx: Sfx
var arena: Arena
var experiment: ExperimentController


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Ui.setup_default_theme()

	ui_layer = CanvasLayer.new()
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)

	main_menu = MainMenu.new()
	ui_layer.add_child(main_menu)
	main_menu.start_pressed.connect(Game.start_run)
	main_menu.experiment_pressed.connect(Game.enter_experiment)
	main_menu.quit_pressed.connect(get_tree().quit)

	hud = Hud.new()
	ui_layer.add_child(hud)

	pause_menu = PauseMenu.new()
	ui_layer.add_child(pause_menu)
	pause_menu.resume_pressed.connect(func() -> void: Game.set_state(GameEnums.GameState.SURVIVAL))
	pause_menu.restart_pressed.connect(Game.start_run)
	pause_menu.menu_pressed.connect(Game.return_to_menu)

	level_up_panel = LevelUpPanel.new()
	ui_layer.add_child(level_up_panel)
	level_up_panel.chosen.connect(_on_upgrade_chosen)

	results_panel = ResultsPanel.new()
	ui_layer.add_child(results_panel)
	results_panel.restart_pressed.connect(Game.start_run)
	results_panel.menu_pressed.connect(Game.return_to_menu)

	sfx = Sfx.new()
	add_child(sfx)

	Game.run_started.connect(_on_run_started)
	Game.state_changed.connect(_on_state_changed)
	EventBus.run_finished.connect(_on_run_finished)


func _on_experiment() -> void:
	pass  # 已直连 Game.enter_experiment


func _on_run_started() -> void:
	## 新一局：重建场地（A10：无上一局残留——敌人/弹体/经验/特效/计时器/待升级全部归零）
	_clear_arena()
	arena = Arena.new()
	add_child(arena)
	hud.bind(arena)


func _on_run_finished(_win: bool, _reason: String) -> void:
	if arena != null:
		results_panel.show_result(Game.run, arena.upgrades.describe_stacks())


func _on_state_changed(_old: GameEnums.GameState, new_state: GameEnums.GameState) -> void:
	main_menu.visible = new_state == GameEnums.GameState.MAIN_MENU
	hud.visible = new_state in [GameEnums.GameState.SURVIVAL, GameEnums.GameState.PAUSED,
			GameEnums.GameState.LEVEL_UP, GameEnums.GameState.RESULTS]
	pause_menu.visible = new_state == GameEnums.GameState.PAUSED
	level_up_panel.visible = level_up_panel.visible and new_state == GameEnums.GameState.LEVEL_UP
	results_panel.visible = results_panel.visible and new_state == GameEnums.GameState.RESULTS
	match new_state:
		GameEnums.GameState.MAIN_MENU:
			_clear_arena()
			_clear_experiment()
		GameEnums.GameState.EXPERIMENT:
			_build_experiment()
		GameEnums.GameState.LEVEL_UP:
			_enter_level_up_flow()
		GameEnums.GameState.SURVIVAL:
			level_up_panel.visible = false


## 试验模式：场地 + 控制器 + 面板（设计文档 9 章）
func _build_experiment() -> void:
	_clear_arena()
	_clear_experiment()
	arena = Arena.new()
	add_child(arena)
	experiment = ExperimentController.new()
	add_child(experiment)
	experiment.setup(arena)
	experiment.build_panel(ui_layer)
	experiment.exit_requested.connect(Game.exit_experiment)


func _clear_experiment() -> void:
	if experiment != null:
		experiment.queue_free()
		experiment = null
	Palette.grayscale = false


## 连续升级：逐次显示升级选择，全部处理完才恢复战斗（设计文档 7.2）
func _enter_level_up_flow() -> void:
	var run := Game.run
	# 全部满级：不显示选择界面，直接恢复 25 生命（满血则恢复 0）
	while run.pending_level_ups > 0 and _candidates().is_empty():
		if arena != null:
			arena.player.hp = mini(arena.player.hp + 25, arena.player.max_hp)
		run.pending_level_ups -= 1
	if run.pending_level_ups == 0:
		Game.set_state(GameEnums.GameState.SURVIVAL)
		return
	_refresh_level_up_cards()


func _candidates() -> Array[UpgradeDef]:
	if arena == null:
		var empty: Array[UpgradeDef] = []
		return empty
	return arena.upgrades.candidates()


func _refresh_level_up_cards() -> void:
	var options := _candidates()
	var previews: Array[String] = []
	for up in options:
		previews.append(arena.upgrades.preview(up))
	level_up_panel.visible = true
	level_up_panel.show_choices(options, previews)


func _on_upgrade_chosen(up: UpgradeDef) -> void:
	arena.upgrades.apply(up)
	Game.run.pending_level_ups -= 1
	if Game.run.pending_level_ups > 0:
		_enter_level_up_flow()  # 继续处理下一次待升级
	else:
		Game.set_state(GameEnums.GameState.SURVIVAL)


func _clear_arena() -> void:
	if arena != null:
		remove_child(arena)
		arena.queue_free()
		arena = null
