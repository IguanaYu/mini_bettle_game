class_name Ui
## UI 构建辅助。首版界面全部代码构建（开发方案决策记录），后续可转 .tscn + 主题。

static func setup_default_theme() -> void:
	## CJK 回退字体：Windows 自带微软雅黑，避免中文显示为方块（开发方案风险表）
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "Noto Sans CJK SC", "sans-serif"])
	ThemeDB.fallback_font = f
	ThemeDB.fallback_font_size = 16


static func button(text: String, min_w := 220.0, min_h := 44.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, min_h)
	return b


static func label(text: String, font_size := 16) -> Label:
	var l := Label.new()
	l.text = text
	if font_size != 16:
		l.add_theme_font_size_override("font_size", font_size)
	return l


static func full_rect(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	return c


static func spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


static func center_panel() -> PanelContainer:
	## 居中面板：全屏暗化背景 + CenterContainer + PanelContainer
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	full_rect(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := Control.new()
	full_rect(root)
	root.add_child(dim)
	var center := CenterContainer.new()
	full_rect(center)
	root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	return panel
