class_name SpawnCurve
extends Resource
## 按生存时间划分的刷怪曲线：Array[SpawnPhaseDef]（开发方案 3.2）。

@export var phases: Array[SpawnPhaseDef] = []


func phase_at(t: float) -> SpawnPhaseDef:
	for p in phases:
		if t >= p.time_from and t < p.time_to:
			return p
	return phases.back() if not phases.is_empty() else null
