extends Node
## 视觉验收脚本：真实渲染运行几秒，截取生存模式与试验模式画面。
## 用法（会短暂弹出游戏窗口）：
##   godot --path . res://tests/screenshot_runner.tscn


func _ready() -> void:
	print("[shot] runner ready")
	await get_tree().process_frame
	var main_scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	print("[shot] main loaded")

	# --- 生存模式：移动 2 秒 + 停 1 秒（敌人聚拢、火球飞行、HUD 在场）---
	Game.start_run()
	print("[shot] run started, state=", Game.state)
	Input.action_press("move_right")
	for i in 120:
		await get_tree().process_frame
		if i % 60 == 0:
			print("[shot] survival frame ", i, " enemies=", main_scene.arena.live_enemy_count()
					if main_scene.arena != null else -1)
	Input.action_release("move_right")
	for i in 60:
		await get_tree().process_frame
	_shot("survival.png")

	# --- 试验模式：单靶 + 面板 ---
	Game.return_to_menu()
	for i in 10:
		await get_tree().process_frame
	Game.enter_experiment()
	print("[shot] experiment entered")
	for i in 30:
		await get_tree().process_frame
	_shot("experiment.png")

	get_tree().quit(0)


func _shot(file_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://docs/screenshots/")
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir + file_name)
	print("[shot] saved ", dir + file_name)
