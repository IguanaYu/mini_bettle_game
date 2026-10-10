extends Node
## 根场景：界面层与场地（Arena）的组装、按状态切换显隐（开发方案 4.1）。
## Phase 0 版本：仅主菜单 + 状态日志；Phase 1/2/3 逐步接入场地与其余界面。

var ui_layer: CanvasLayer
var main_menu: MainMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Ui.setup_default_theme()

	ui_layer = CanvasLayer.new()
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)

	main_menu = MainMenu.new()
	ui_layer.add_child(main_menu)
	main_menu.start_pressed.connect(_on_start)
	main_menu.experiment_pressed.connect(_on_experiment)
	main_menu.quit_pressed.connect(get_tree().quit)


func _on_start() -> void:
	print("[main] 开始生存（Phase 2 接入场地）")


func _on_experiment() -> void:
	print("[main] 特效试验（Phase 3 接入试验场）")
