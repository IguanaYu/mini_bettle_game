class_name ResultsPanel
extends Control
## 结算界面：胜负原因、生存时间、击杀、最终等级、已选强化（设计文档 8.1）。

signal restart_pressed
signal menu_pressed

var title_label: Label
var stats_label: Label
var upgrades_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var panel := Ui.center_panel()
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(360, 0)
	panel.add_child(box)

	title_label = Ui.label("", 26)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	stats_label = Ui.label("")
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(stats_label)
	upgrades_label = Ui.label("", 14)
	upgrades_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrades_label.modulate = Color(1, 1, 1, 0.75)
	box.add_child(upgrades_label)
	box.add_child(Ui.spacer(16))

	var b_restart := Ui.button("重开")
	b_restart.pressed.connect(func() -> void: restart_pressed.emit())
	box.add_child(b_restart)
	var b_menu := Ui.button("返回主菜单")
	b_menu.pressed.connect(func() -> void: menu_pressed.emit())
	box.add_child(b_menu)


func show_result(run: RunContext, upgrade_summaries: Array) -> void:
	title_label.text = ("胜利！生存满 300 秒" if run.result_win else "失败：%s" % run.result_reason)
	title_label.add_theme_color_override("font_color",
			Color(0.55, 1.0, 0.6) if run.result_win else Color(1.0, 0.55, 0.5))
	var t := int(round(run.elapsed))
	stats_label.text = "生存 %02d:%02d　击杀 %d　最终等级 %d" % [t / 60, t % 60, run.kills, run.level]
	upgrades_label.text = "已选强化：" + ("、".join(upgrade_summaries) if not upgrade_summaries.is_empty() else "无")
	visible = true
