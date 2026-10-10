extends Node
## 真实输入管线验收（窗口模式运行，会短暂弹出游戏窗口）：
##   godot --path . res://tests/real_input_runner.tscn
## 用 Input.parse_input_event 注入与 OS 输入完全同链路的鼠标/键盘事件：
## 菜单点击（GUI 拾取）→ Esc 暂停 → Esc 恢复 → 截图 → 按结果退出。
## 退出码 0 = 全部通过；1 = 有失败。

var failures: Array[String] = []
var main_scene: Node


func _ready() -> void:
	await get_tree().process_frame
	main_scene = load("res://scenes/main.tscn").instantiate()
	add_child(main_scene)
	for i in 30:
		await get_tree().process_frame

	# 1) 点击主菜单"开始生存"：走真实 GUI 拾取管线
	var btn := _find_button(main_scene.main_menu, "开始生存")
	_check("找到开始生存按钮", btn != null)
	if btn:
		_click_control(btn)
		for i in 30:
			await get_tree().process_frame
		_check("点击后进入生存状态", Game.state == GameEnums.GameState.SURVIVAL,
				"state=%s" % GameEnums.GameState.keys()[Game.state])
		_check("场地与 HUD 已建立", main_scene.arena != null and main_scene.hud.visible)

	# 2) 战斗 2 秒，制造敌人与弹体画面
	for i in 120:
		await get_tree().process_frame

	# 3) Esc 暂停 → 再 Esc 恢复（真实按键事件）
	_press_key(KEY_ESCAPE)
	for i in 10:
		await get_tree().process_frame
	_check("Esc 进入暂停", Game.state == GameEnums.GameState.PAUSED,
			"state=%s" % GameEnums.GameState.keys()[Game.state])
	_press_key(KEY_ESCAPE)
	for i in 10:
		await get_tree().process_frame
	_check("再 Esc 恢复战斗", Game.state == GameEnums.GameState.SURVIVAL,
			"state=%s" % GameEnums.GameState.keys()[Game.state])

	# 4) 证据截图
	var img := get_viewport().get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://docs/screenshots/")
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir + "real_input_play.png")
	print("[real-input] 截图已保存 docs/screenshots/real_input_play.png")

	# 5) Esc 暂停 → 点击暂停菜单"返回主菜单"（再次 GUI 拾取）
	_press_key(KEY_ESCAPE)
	for i in 10:
		await get_tree().process_frame
	var menu_btn := _find_button(main_scene.pause_menu, "返回主菜单")
	_check("暂停菜单有返回按钮", menu_btn != null)
	if menu_btn:
		_click_control(menu_btn)
		for i in 30:
			await get_tree().process_frame
		_check("点击返回主菜单生效", Game.state == GameEnums.GameState.MAIN_MENU,
				"state=%s" % GameEnums.GameState.keys()[Game.state])

	print("[real-input] 结果: %d 失败" % failures.size())
	for f in failures:
		print("[real-input] 失败项: %s" % f)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _check(name: String, ok: bool, detail := "") -> void:
	if ok:
		print("[real-input] PASS %s" % name)
	else:
		failures.append(name)
		print("[real-input] FAIL %s  %s" % [name, detail])


func _click_control(c: Control) -> void:
	## 注入一次真实鼠标点击（OS 事件同链路：parse_input_event → Viewport → GUI 拾取）
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


func _press_key(keycode: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.physical_keycode = keycode
	press.pressed = true
	Input.parse_input_event(press)
	var release: InputEventKey = press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node
	for c in node.get_children():
		var found := _find_button(c, text)
		if found != null:
			return found
	return null
