class_name LevelUpPanel
extends Control
## 升级选择界面：最多 3 张强化卡片，鼠标点击或数字键 1-3 选择（设计文档 8.1 / 8.2）。

signal chosen(upgrade: UpgradeDef)

var cards: Array[Button] = []
var card_upgrades: Array[UpgradeDef] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size = Vector2(360, 0)
	panel.add_child(box)

	var title := Ui.label("升级！选择一项强化", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	for i in 3:
		var card := Button.new()
		card.custom_minimum_size = Vector2(330, 86)
		card.add_theme_font_size_override("font_size", 17)
		var idx := i
		card.pressed.connect(func() -> void: _pick(idx))
		box.add_child(card)
		cards.append(card)
		card_upgrades.append(null)
	var hint := Ui.label("鼠标点击或按 1 / 2 / 3 选择", 13)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1, 1, 1, 0.6)
	box.add_child(hint)


func show_choices(options: Array[UpgradeDef], previews: Array[String]) -> void:
	for i in cards.size():
		var has_option := i < options.size()
		cards[i].visible = has_option
		if has_option:
			card_upgrades[i] = options[i]
			cards[i].text = "%s\n%s" % [options[i].display_name, previews[i]]
	visible = true


func _pick(index: int) -> void:
	if not visible or index >= card_upgrades.size() or card_upgrades[index] == null:
		return
	var up := card_upgrades[index]
	visible = false
	chosen.emit(up)


func _unhandled_input(event: InputEvent) -> void:
	## 数字键选择；输入框持有焦点时不作为快捷键（设计文档 8.2）
	if not visible or Game.ui_has_focus():
		return
	if event.is_action_pressed("choose_1"):
		_pick(0)
	elif event.is_action_pressed("choose_2"):
		_pick(1)
	elif event.is_action_pressed("choose_3"):
		_pick(2)
