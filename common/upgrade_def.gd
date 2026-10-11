class_name UpgradeDef
extends Resource
## 声明式强化条目（设计文档 7.3）：数值全部在 balance/upgrades/ 的 .tres 中。

enum StatKind { FIRE_DAMAGE, FIRE_INTERVAL, MOVE_SPEED, PICKUP_RADIUS, MAX_HP,
		UNLOCK_SCATTER, SCATTER_COUNT, UNLOCK_FIRE_EGG }  # 后三项：武器解锁/强化（火系武器扩展设计）
enum Op { FLAT_ADD, MULTIPLY }

@export var id: StringName = &""
@export var display_name: String = ""
@export var stat: StatKind = StatKind.FIRE_DAMAGE
@export var op: Op = Op.FLAT_ADD
@export var flat_amount: float = 5.0  # FLAT_ADD 每次增量
@export var factor: float = 0.9       # MULTIPLY 系数（攻速）
@export var max_stacks: int = 5
@export var clamp_min: float = -1.0   # 仅攻速填 0.55（间隔下限）；-1 表示无下限
@export var heal_on_stack: int = 0    # 仅最大生命条目：升级上限 +10 同时回 10
