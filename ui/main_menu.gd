class_name MainMenu
extends Control
## 主菜单：开始生存 / 特效试验 / 退出（设计文档 8.1）。

signal start_pressed
signal experiment_pressed
signal quit_pressed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.10)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)

	var title := Ui.label("xixuegui1010", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := Ui.label("俯视 2D 生存原型 · 特效试验场", 15)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(1, 1, 1, 0.7)
	box.add_child(sub)
	box.add_child(_spacer(24))

	var b_start := Ui.button("开始生存")
	b_start.pressed.connect(func() -> void: start_pressed.emit())
	box.add_child(b_start)

	var b_test := Ui.button("特效试验")
	b_test.pressed.connect(func() -> void: experiment_pressed.emit())
	box.add_child(b_test)

	var b_quit := Ui.button("退出")
	b_quit.pressed.connect(func() -> void: quit_pressed.emit())
	box.add_child(b_quit)


static func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
