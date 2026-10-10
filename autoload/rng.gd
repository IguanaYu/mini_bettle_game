extends Node
## 统一随机数服务：gameplay 代码一律经由本节点取随机数，保证试验种子可控（开发方案 3.4）。
## 除本文件 _ready 的开局熵源外，项目内禁止使用全局 randi()/randf()。

var game_rng := RandomNumberGenerator.new()

func _ready() -> void:
	reseed(randi())  # 项目中唯一允许的全局随机调用：生存模式开局种子

func reseed(seed_value: int) -> void:
	game_rng.seed = seed_value

func randf() -> float:
	return game_rng.randf()

func randf_range(from: float, to: float) -> float:
	return game_rng.randf_range(from, to)

func randi_range(from: int, to: int) -> int:
	return game_rng.randi_range(from, to)

func shuffled(arr: Array) -> Array:
	## Fisher-Yates 洗牌（RandomNumberGenerator 没有 shuffle 方法，手写以保持种子可控）
	var copy := arr.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j := game_rng.randi_range(0, i)
		var tmp = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy
