class_name Palette
## 全局调色辅助：灰度开关作用于所有程序化绘制（试验模式可读性辅助，设计文档 9.4）。

static var grayscale := false:
	set(value):
		grayscale = value
		RenderingServer.global_shader_parameter_set("art_grayscale", value)
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			tree.call_group("world_art", "queue_redraw")


static func c(col: Color) -> Color:
	if not grayscale:
		return col
	var l := col.get_luminance()
	return Color(l, l, l, col.a)
