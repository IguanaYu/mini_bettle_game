class_name XpManager
extends Node
## 经验掉落、吸取、合并与升级检测（设计文档 7.1 / 7.2）。

const MERGE_INTERVAL := 2.0  # 合并扫描周期：防长时间积累对象
const MERGE_RADIUS := 24.0

var arena: Arena
var gems: Array[ExpGem] = []
var merge_timer := 0.0


func setup(a: Arena) -> void:
	arena = a


func clear_gems() -> void:
	for g in gems:
		g.queue_free()
	gems.clear()


func spawn_gem(pos: Vector2, value: int) -> void:
	var g := ExpGem.new()
	g.value = value
	g.position = pos
	g.player = arena.player
	arena.add_child(g)
	gems.append(g)


func tick(delta: float) -> void:
	if arena.is_experiment:
		return  # 试验靶场不掉经验、不升级（设计文档 9.1）
	var p := arena.player
	for g in gems:
		g.tick(delta)
		if not g.attracted and g.position.distance_to(p.position) < p.pickup_radius:
			g.attracted = true
		if g.attracted:
			# 已开始吸取的经验物继续追随玩家（设计文档 7.1）
			var dir: Vector2 = p.position - g.position
			if dir.length() > 0.0001:
				g.position += dir.normalized() * g.attract_speed * delta
	merge_timer += delta
	if merge_timer >= MERGE_INTERVAL:
		merge_timer = 0.0
		_merge_scan()
	_collect()


func collect_xp(value: int) -> void:
	var run := Game.run
	if run == null:
		return
	run.xp += value
	EventBus.xp_collected.emit(value, run.xp, run.level)
	# 一次拾取跨过多个阈值：逐次累计待升级次数，剩余经验保留（设计文档 7.2，验收 A06）
	while run.xp >= RunContext.xp_threshold(run.level):
		run.xp -= RunContext.xp_threshold(run.level)
		run.level += 1
		run.pending_level_ups += 1
	if run.pending_level_ups > 0:
		EventBus.level_up_pending.emit(run.pending_level_ups)


func _collect() -> void:
	var p := arena.player
	for i in range(gems.size() - 1, -1, -1):
		if gems[i].position.distance_to(p.position) < p.radius + 4.0:
			var g := gems[i]
			gems.remove_at(i)
			g.queue_free()
			collect_xp(g.value)


func _merge_scan() -> void:
	## 合并彼此接近的经验物，合并前后总价值守恒（设计文档 7.1）
	if gems.size() < 2:
		return
	var i := 0
	while i < gems.size():
		var j := i + 1
		while j < gems.size():
			if gems[i].position.distance_to(gems[j].position) < MERGE_RADIUS:
				gems[i].value += gems[j].value
				gems[j].queue_free()
				gems.remove_at(j)
			else:
				j += 1
		i += 1
