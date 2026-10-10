extends Node
## 游戏流程状态机：状态转移、暂停/慢放管理、本局上下文（开发方案 2.3）。
##
## 暂停语义：进入 SURVIVAL / EXPERIMENT / MAIN_MENU 以外的状态时 tree.paused = true；
## 试验模式内部的"播放暂停"（PlaybackRate.PAUSED）由 ExperimentController 直接控制
## tree.paused，不经过状态机。

signal state_changed(old_state: GameEnums.GameState, new_state: GameEnums.GameState)
signal run_started  # 新一局开始（开始生存或重开），UI 收到后重建场地

const RUN_DURATION := 300.0  # 生存目标：300 秒（设计文档 3.2）

var state: GameEnums.GameState = GameEnums.GameState.MAIN_MENU
var run: RunContext
var in_experiment := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.level_up_pending.connect(_on_level_up_pending)

func is_playing() -> bool:
	## 世界是否处于推进状态（决定是否累计时间等）
	return state == GameEnums.GameState.SURVIVAL or state == GameEnums.GameState.EXPERIMENT

func ui_has_focus() -> bool:
	## 输入数值框持有焦点时不触发移动与快捷键（设计文档 8.2）
	var f := get_viewport().gui_get_focus_owner()
	return f != null and (f is LineEdit or f is SpinBox or f is TextEdit)

func set_state(new_state: GameEnums.GameState) -> void:
	if new_state == state:
		return
	var old := state
	state = new_state
	var world_running := new_state == GameEnums.GameState.SURVIVAL \
			or new_state == GameEnums.GameState.EXPERIMENT \
			or new_state == GameEnums.GameState.MAIN_MENU
	get_tree().paused = not world_running
	state_changed.emit(old, new_state)

func start_run() -> void:
	## 开始生存 / 重开：全新上下文，由 UI 重建场地
	Engine.time_scale = 1.0
	get_tree().paused = false
	in_experiment = false
	run = RunContext.new()
	run_started.emit()
	set_state(GameEnums.GameState.SURVIVAL)

func return_to_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	in_experiment = false
	run = null
	set_state(GameEnums.GameState.MAIN_MENU)

func enter_experiment() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	in_experiment = true
	set_state(GameEnums.GameState.EXPERIMENT)

func exit_experiment() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	in_experiment = false
	set_state(GameEnums.GameState.MAIN_MENU)

func finish_run(win: bool, reason: String) -> void:
	## 结算只生成一次；同帧死亡与满 300 秒时由调用方保证死亡优先（设计文档 3.2）
	if run == null or run.finished:
		return
	run.finished = true
	run.result_win = win
	run.result_reason = reason
	EventBus.run_finished.emit(win, reason)
	set_state(GameEnums.GameState.RESULTS)

func _on_level_up_pending(pending_count: int) -> void:
	if pending_count > 0 and state == GameEnums.GameState.SURVIVAL:
		set_state(GameEnums.GameState.LEVEL_UP)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not ui_has_focus():
		match state:
			GameEnums.GameState.SURVIVAL:
				set_state(GameEnums.GameState.PAUSED)
			GameEnums.GameState.PAUSED:
				set_state(GameEnums.GameState.SURVIVAL)
			# EXPERIMENT 的 Esc 由试验面板（退出与重置菜单）处理
