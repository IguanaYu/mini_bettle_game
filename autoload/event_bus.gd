extends Node
## 全局信号总线。UI 与特效只经信号感知 gameplay，不反向引用（开发方案 2.4）。

signal attack_fired(element: int, attack_id: int, pos: Vector2, dir: Vector2)
signal attack_hit(attack_id: int, target_id: int, pos: Vector2, element: int, killed: bool)
signal attack_expired(attack_id: int, pos: Vector2, element: int)

signal enemy_spawned(enemy_id: int)
signal enemy_recycled(enemy_id: int)

signal player_damaged(amount: int, hp_left: int)

signal xp_collected(value: int, total_xp: int, level: int)
signal level_up_pending(pending_count: int)
signal upgrade_chosen(upgrade_id: StringName, stacks: int, summary: String)

signal run_finished(win: bool, reason: String)
