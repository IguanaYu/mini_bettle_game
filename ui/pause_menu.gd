class_name PauseMenu
extends Control
## 暂停界面：继续 / 重开 / 返回主菜单（设计文档 8.1）。

signal resume_pressed
signal restart_pressed
signal menu_pressed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var panel := Ui.center_panel()
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := Ui.label("已暂停", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var b_resume := Ui.button("继续")
	b_resume.pressed.connect(func() -> void: resume_pressed.emit())
	box.add_child(b_resume)
	var b_restart := Ui.button("重开")
	b_restart.pressed.connect(func() -> void: restart_pressed.emit())
	box.add_child(b_restart)
	var b_menu := Ui.button("返回主菜单")
	b_menu.pressed.connect(func() -> void: menu_pressed.emit())
	box.add_child(b_menu)
