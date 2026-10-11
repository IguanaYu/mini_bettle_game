class_name ScatterManager
extends Node
## W01 扇形散射火球控制器（火系武器扩展设计 3）。
## 弹体复用 Fireball 实体与 ProjectileManager 的推进/扫掠/命中管线：
## 本类只负责目标选择、冷却与扇形展开；一次齐射只发一次开火事件与一次发射闪光。

var arena: Arena
var rule: ScatterRule
var active := false
var auto_fire := true
var cooldown := 0.0


func setup(a: Arena, r: ScatterRule) -> void:
	arena = a
	rule = r


func activate(r: ScatterRule) -> void:
	## 升级解锁：从基础规则副本开始
	rule = r
	active = true
	cooldown = 0.0


func tick(delta: float) -> void:
	if not active or not auto_fire:
		return
	cooldown -= delta
	if cooldown > 0.0:
		return
	var target := arena.projectiles.find_target()
	if target == null:
		cooldown = 0.0  # 无有效目标不发射，进入下一次正常间隔（设计文档 6.1）
		return
	fire_volley(target)
	cooldown += rule.fire_interval


func fire_volley(target: Node2D) -> void:
	var base: Vector2 = (target.position - arena.player.position).normalized()
	var n := maxi(1, rule.pellet_count)
	var first_id := -1
	for i in n:
		# 中间一发正对基准方向，两侧对称等分总角（W01 3.3）
		var off := 0.0
		if n > 1:
			off = deg_to_rad(rule.spread_deg) * (float(i) / float(n - 1) - 0.5)
		var ball := arena.projectiles.fire_dir(base.rotated(off), rule, false, false)
		if first_id < 0:
			first_id = ball.attack_id
	arena.fx_layer.spawn_muzzle(arena.player.position, base, arena.projectiles.current_visual)
	EventBus.attack_fired.emit(rule.element, first_id, arena.player.position, base)
