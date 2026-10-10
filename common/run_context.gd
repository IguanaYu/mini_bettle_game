class_name RunContext
extends RefCounted
## 一局游戏的全部可变状态（开发方案 3.3）。重开 = 重建本对象 + 重建场地。

var elapsed: float = 0.0       # 本局生存时间（暂停期间不推进）
var kills: int = 0
var level: int = 1
var xp: int = 0
var pending_level_ups: int = 0  # 连续升级队列（设计文档 7.2）
var upgrade_stacks: Dictionary = {}  # StringName(upgrade_id) -> 已叠层数
var finished: bool = false
var result_win: bool = false
var result_reason: String = ""


static func xp_threshold(level: int) -> int:
	## 升级所需经验：L 级 → 20 + 10 * (L-1)（设计文档 7.2）
	return 20 + 10 * (level - 1)
