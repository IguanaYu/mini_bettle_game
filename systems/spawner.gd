class_name Spawner
extends Node
## 分段刷怪：间隔、存活上限、镜头外生成、超距回收（设计文档 5.2，验收 A15）。

var arena: Arena
var curve: SpawnCurve
var enabled := true
var next_spawn_time := 0.0
var serial := 0                # 敌人生成序号（同时是 tie-break 依据）
var max_alive_override := -1   # 试验模式可指定敌人上限；-1 用曲线值


func setup(a: Arena) -> void:
	arena = a
	curve = load("res://balance/spawn_curve.tres")


func next_serial() -> int:
	serial += 1
	return serial


func reset_clock() -> void:
	next_spawn_time = 0.0


func tick(delta: float, elapsed: float) -> void:
	if not enabled:
		return
	var phase := curve.phase_at(elapsed)
	if phase == null:
		return
	if elapsed >= next_spawn_time:
		# 达上限时跳过本次刷新，不累积欠账（设计文档 5.2）
		next_spawn_time = elapsed + phase.spawn_interval
		var cap := phase.max_alive if max_alive_override < 0 else max_alive_override
		if arena.live_enemy_count() < cap:
			_spawn(phase)


func _spawn(phase: SpawnPhaseDef) -> void:
	var e := Enemy.new()
	e.setup(arena.enemy_def, next_serial(), phase.chase_speed, arena.player)
	e.position = _edge_position()
	arena.add_child(e)
	arena.enemies.append(e)
	EventBus.enemy_spawned.emit(e.id)


## 镜头四边之外至少 64px 的随机位置（设计文档 5.2）
func _edge_position() -> Vector2:
	var cam := arena.camera.position
	var half := Vector2(640.0, 360.0)  # 设计视口一半；窗口缩放不改世界参数
	var margin := Rng.randf_range(64.0, 160.0)
	match Rng.randi_range(0, 3):
		0: return cam + Vector2(-half.x - margin, Rng.randf_range(-half.y, half.y))
		1: return cam + Vector2(half.x + margin, Rng.randf_range(-half.y, half.y))
		2: return cam + Vector2(Rng.randf_range(-half.x, half.x), -half.y - margin)
		_: return cam + Vector2(Rng.randf_range(-half.x, half.x), half.y + margin)
