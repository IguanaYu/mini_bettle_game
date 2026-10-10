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
	var copy := arr.duplicate()
	game_rng.shuffle(copy)
	return copy
