class_name FireEggRule
extends Resource
## 火蛋规则（火系武器扩展设计 W07）：慢速投掷物，终点（命中/撞墙/到期）生成燃烧区域。
## 火蛋本体不直接造成伤害，燃烧区域按 tick 采样结算——范围伤害是显式规则而非视觉。

@export var element: GameEnums.ElementKind = GameEnums.ElementKind.FIRE
@export var fire_interval: float = 2.5
@export var aim_range: float = 900.0
@export var projectile_speed: float = 160.0  # 约火球 1/3：慢速可读的投掷弧线（俯视直线）
@export var lifetime: float = 3.0
@export var hit_radius: float = 10.0
@export var pool_radius: float = 40.0        # 燃烧区域半径 = 预警视觉半径（诚实范围）
@export var pool_duration: float = 3.0
@export var pool_tick_interval: float = 0.5
@export var pool_damage: float = 5.0         # 每跳 5，6 跳总伤 30 恰好烧死初始敌
@export var max_pools: int = 12              # 同屏上限：超出时最旧一片提前熄灭
