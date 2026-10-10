class_name PlayerDef
extends Resource
## 玩家基础参数（设计文档 4.2）。

@export var max_hp: int = 100
@export var move_speed: float = 220.0
@export var body_radius: float = 12.0
@export var contact_iframes: float = 0.6  # 接触伤害后的无敌时间
@export var xp_pickup_radius: float = 50.0
