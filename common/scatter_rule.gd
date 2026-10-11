class_name ScatterRule
extends AttackRule
## 扇形散射火球规则（火系武器扩展设计 W01）：一次开火沿基准方向扇形展开多发小火球。
## 继承的弹体字段（伤害/速度/寿命/碰撞半径/穿透）由 ProjectileManager 统一推进，
## 本类只补充扇形展开参数。

@export var pellet_count: int = 3      # 每次开火弹体数；强化 +1/次，上限 5
@export var spread_deg: float = 24.0   # 扇形总角：多发等分，中间一发正对基准方向
