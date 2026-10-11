class_name Spawner
extends Node
## 分段刷怪：间隔、存活上限、墙边生成、超距回收（设计文档 5.2，验收 A15）。
## 封闭竞技场：敌人从四面墙内侧出现（Brotato 式），不再依赖镜头外生成。

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


## 四面墙内侧的随机位置：沿边随机 + 离墙 24~96px 内缩（封闭场地，Brotato 式）
func _edge_position() -> Vector2:
	var inner := Arena.arena_inner_rect()
	var margin := Rng.randf_range(Arena.WALL, Arena.WALL + 72.0)
	var x := Rng.randf_range(inner.position.x + margin, inner.end.x - margin)
	var y := Rng.randf_range(inner.position.y + margin, inner.end.y - margin)
	match Rng.randi_range(0, 3):
		0: return Vector2(inner.position.x + margin, y)
		1: return Vector2(inner.end.x - margin, y)
		2: return Vector2(x, inner.position.y + margin)
		_: return Vector2(x, inner.end.y - margin)
