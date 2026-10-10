class_name AttackRule
extends Resource
## 火球（直线弹道）攻击规则：纯数值，与视觉完全分离（开发方案 3.2）。
## 数值为设计文档 6.2 建议初始值。

@export var element: GameEnums.ElementKind = GameEnums.ElementKind.FIRE
@export var damage: float = 20.0
@export var fire_interval: float = 1.0
@export var aim_range: float = 900.0
@export var projectile_speed: float = 480.0
@export var lifetime: float = 2.0
@export var hit_radius: float = 8.0  # 碰撞半径，与可见主体大小分开配置
@export var pierce: int = 0
