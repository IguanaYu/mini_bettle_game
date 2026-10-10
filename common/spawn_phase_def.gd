class_name SpawnPhaseDef
extends Resource
## 一段刷怪参数（设计文档 5.2），覆盖生存时间 [time_from, time_to)。

@export var time_from: float = 0.0
@export var time_to: float = 60.0
@export var spawn_interval: float = 1.3
@export var max_alive: int = 60
@export var chase_speed: float = 80.0
