class_name EnemyDef
extends Resource
## 普通敌人参数（设计文档 5.1）。

@export var max_hp: float = 30.0
@export var body_radius: float = 12.0
@export var contact_damage: int = 10
@export var xp_value: int = 5
@export var hit_flash_time: float = 0.08
@export var dissolve_time: float = 0.18  # 死亡消散时长，开始死亡即撤销碰撞
