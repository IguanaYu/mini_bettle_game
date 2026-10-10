class_name Geo
## 纯几何工具（开发方案 5.3）。所有命中检测的数学基础，可单元测试。


## 线段 p0→p1 与圆 (c, r) 的最早交点参数 t∈[0,1]；未命中返回 -1。
## 用于弹体本帧移动路径的连续命中检测，防止高速穿透（验收 A03）。
static func segment_hit_t(p0: Vector2, p1: Vector2, c: Vector2, r: float) -> float:
	var d := p1 - p0
	var f := p0 - c
	var a := d.dot(d)
	var cc := f.dot(f) - r * r
	if cc <= 0.0:
		return 0.0  # 起点已在圆内
	if a <= 0.0000001:
		return -1.0  # 本帧未移动
	var b := 2.0 * f.dot(d)
	var disc := b * b - 4.0 * a * cc
	if disc < 0.0:
		return -1.0
	var t := (-b - sqrt(disc)) / (2.0 * a)
	if t < 0.0 or t > 1.0:
		return -1.0
	return t
