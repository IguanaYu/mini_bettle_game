class_name UpgradeSystem
extends Node
## 强化候选抽取与应用（设计文档 7.3）。卡片显示实际变化，如"火球伤害 20 → 25"。

var arena: Arena
var db: Array[UpgradeDef] = []


func setup(a: Arena) -> void:
	arena = a
	for key in ["fire_damage", "fire_rate", "move_speed", "pickup_radius", "max_hp",
			"unlock_scatter", "scatter_count", "unlock_fire_egg"]:
		db.append(load("res://balance/upgrades/%s.tres" % key))


## 全部当前可选条目（未满级 + 前置满足）：武器强化卡只在持有该武器后出现
func _available() -> Array[UpgradeDef]:
	var pool: Array[UpgradeDef] = []
	var run := Game.run
	if run == null:
		return pool
	var scatter_unlocked := int(run.upgrade_stacks.get(&"unlock_scatter", 0)) > 0
	for up in db:
		if int(run.upgrade_stacks.get(up.id, 0)) >= up.max_stacks:
			continue
		if up.stat == UpgradeDef.StatKind.SCATTER_COUNT and not scatter_unlocked:
			continue
		pool.append(up)
	return pool


## 从仍可升级的条目中随机抽取最多三个不同选项（验收 A14）
func candidates() -> Array[UpgradeDef]:
	var order := Rng.shuffled(_available())
	var out: Array[UpgradeDef] = []
	for i in mini(3, order.size()):
		out.append(order[i])
	return out


## 不应用、只生成文案（升级卡片显示用）
func preview(up: UpgradeDef) -> String:
	return _apply(up, false)


func apply(up: UpgradeDef) -> String:
	return _apply(up, true)


func _apply(up: UpgradeDef, commit: bool) -> String:
	var run := Game.run
	var p := arena.player
	var rule := arena.projectiles.rule
	var old_v := 0.0
	var new_v := 0.0
	var custom_summary := ""
	match up.stat:
		UpgradeDef.StatKind.FIRE_DAMAGE:
			old_v = rule.damage
			new_v = old_v + up.flat_amount
			if commit:
				rule.damage = new_v
		UpgradeDef.StatKind.FIRE_INTERVAL:
			old_v = rule.fire_interval
			# 攻速乘 0.9，间隔不低于下限 0.55（设计文档 7.3）
			new_v = maxf(up.clamp_min, old_v * up.factor)
			if commit:
				rule.fire_interval = new_v
		UpgradeDef.StatKind.MOVE_SPEED:
			old_v = p.move_speed
			new_v = old_v + up.flat_amount
			if commit:
				p.move_speed = new_v
		UpgradeDef.StatKind.PICKUP_RADIUS:
			old_v = p.pickup_radius
			new_v = old_v + up.flat_amount
			if commit:
				p.pickup_radius = new_v
		UpgradeDef.StatKind.MAX_HP:
			old_v = p.max_hp
			new_v = old_v + up.flat_amount
			if commit:
				p.max_hp = int(new_v)
				if up.heal_on_stack > 0:  # 上限 +10 同时恢复 10
					p.hp = mini(p.hp + up.heal_on_stack, p.max_hp)
		UpgradeDef.StatKind.UNLOCK_SCATTER:
			if commit:
				arena.scatter.activate(arena.scatter_rule_base.duplicate())
			custom_summary = "一次 %d 发扇形散射" % arena.scatter_rule_base.pellet_count
		UpgradeDef.StatKind.SCATTER_COUNT:
			old_v = arena.scatter.rule.pellet_count
			new_v = old_v + 1.0
			if commit:
				arena.scatter.rule.pellet_count = int(new_v)
		UpgradeDef.StatKind.UNLOCK_FIRE_EGG:
			if commit:
				arena.fire_eggs.activate(arena.fire_egg_rule_base.duplicate())
			custom_summary = "慢速投掷，落点留下燃烧区域"
	var summary := custom_summary
	if summary.is_empty():
		summary = "%s %s → %s" % [up.display_name, _fmt(up.stat, old_v), _fmt(up.stat, new_v)]
	if commit and run != null:
		run.upgrade_stacks[up.id] = int(run.upgrade_stacks.get(up.id, 0)) + 1
		EventBus.upgrade_chosen.emit(up.id, run.upgrade_stacks[up.id], summary)
	return summary


func _fmt(stat: UpgradeDef.StatKind, v: float) -> String:
	if stat == UpgradeDef.StatKind.FIRE_INTERVAL:
		return "%.2fs" % v
	return str(int(round(v)))


## 结算面板用：已选强化清单
func describe_stacks() -> Array[String]:
	var out: Array[String] = []
	var run := Game.run
	if run == null:
		return out
	for up in db:
		var stacks := int(run.upgrade_stacks.get(up.id, 0))
		if stacks > 0:
			out.append("%s ×%d" % [up.display_name, stacks])
	return out
