extends Node
## 根场景：界面层与场地（Arena）的组装、按状态切换显隐（开发方案 4.1）。
## Phase 1 版本：主菜单 + 生存场地 + 音效；HUD/暂停菜单/升级/结算是 Phase 2。

var ui_layer: CanvasLayer
var main_menu: MainMenu
var sfx: Sfx
var arena: Arena


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Ui.setup_default_theme()

	ui_layer = CanvasLayer.new()
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)

	main_menu = MainMenu.new()
	ui_layer.add_child(main_menu)
	main_menu.start_pressed.connect(Game.start_run)
	main_menu.experiment_pressed.connect(_on_experiment)
	main_menu.quit_pressed.connect(get_tree().quit)

	sfx = Sfx.new()
	add_child(sfx)

	Game.run_started.connect(_on_run_started)
	Game.state_changed.connect(_on_state_changed)


func _on_experiment() -> void:
	print("[main] 特效试验（Phase 3 接入试验场）")


func _on_run_started() -> void:
	_clear_arena()
	arena = Arena.new()
	add_child(arena)


func _on_state_changed(_old: GameEnums.GameState, new_state: GameEnums.GameState) -> void:
	main_menu.visible = new_state == GameEnums.GameState.MAIN_MENU
	if new_state == GameEnums.GameState.MAIN_MENU:
		_clear_arena()


func _clear_arena() -> void:
	if arena != null:
		remove_child(arena)
		arena.queue_free()
		arena = null
