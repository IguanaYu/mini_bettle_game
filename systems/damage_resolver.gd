class_name DamageResolver
extends RefCounted
## 唯一伤害/死亡管线（开发方案 5.4）。所有来源的伤害（火球/接触/未来的闪电与水波）
## 共用 apply_damage，保证死亡唯一处理与同攻击去重。


## 结算一次伤害。返回是否发生了有效命中。
## 顺序固定：守卫 → 扣血 → 受击表现 → 死亡流程（设计文档 6.4）。
static func apply_damage(target: Enemy, amount: float, attack_id: int,
		element: GameEnums.ElementKind, arena: Arena) -> bool:
	# 守卫 1：只有 ALIVE 敌人可受伤——死亡唯一处理（设计文档 5.3）
	if target.state != GameEnums.EnemyState.ALIVE:
		return false
	# 守卫 2：同一攻击对同一目标至多结算一次（穿透 / 试验靶场回血，设计文档 9.1）
	if attack_id >= 0 and target.last_hit_attack_ids.has(attack_id):
		return false
	target.last_hit_attack_ids[attack_id] = true

	target.hp -= amount
	target.flash_timer = target.def.hit_flash_time

	var killed := false
	if target.is_target:
		# 试验固定靶：结算完本次伤害后恢复满生命，不进入死亡流程（设计文档 9.1）
		if target.hp <= 0.0:
			target.hp = target.def.max_hp
	elif target.hp <= 0.0:
		killed = true
		target.state = GameEnums.EnemyState.DYING
		target.dissolve_timer = target.def.dissolve_time
		arena.on_enemy_killed(target)

	EventBus.attack_hit.emit(attack_id, target.id, target.position, element, killed)
	return true
