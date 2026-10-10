class_name Palette
## 全局调色辅助：灰度开关作用于所有程序化绘制（试验模式可读性辅助，设计文档 9.4）。

static var grayscale := false


static func c(col: Color) -> Color:
	if not grayscale:
		return col
	var l := col.get_luminance()
	return Color(l, l, l, col.a)
