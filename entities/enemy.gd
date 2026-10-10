class_name Enemy
extends Node2D
## 敌人实体。追击/受击/消散由 Arena._step 驱动（tick）。

var def: EnemyDef
var id := -1                  # 生成序号：目标距离并列时的 tie-break（设计文档 6.1）
var state: GameEnums.EnemyState = GameEnums.EnemyState.ALIVE
var hp: float
var radius: float
var chase_speed := 80.0
var flash_timer := 0.0
var dissolve_timer := 0.0
var is_target := false        # 试验固定靶：不移动、不掉落、命中结算后回满血
var last_hit_attack_ids: Dictionary = {}  # attack_id -> true：防同攻击重复命中
var player: Player


func setup(d: EnemyDef, spawn_id: int, speed: float, p: Player) -> void:
	def = d
	id = spawn_id
	hp = d.max_hp
	radius = d.body_radius
	chase_speed = speed
	player = p


func tick(delta: float) -> void:
	match state:
		GameEnums.EnemyState.ALIVE:
			# 追赶玩家当前位置（设计文档 5.1）；固定靶不动
			if not is_target and player != null:
				var to_p: Vector2 = player.position - position
				if to_p.length() > 0.0001:
					position += to_p.normalized() * chase_speed * delta
			if flash_timer > 0.0:
				flash_timer = maxf(0.0, flash_timer - delta)
		GameEnums.EnemyState.DYING:
			# 死亡消散：开始死亡即已撤销碰撞，仅播完视觉（设计文档 5.1）
			dissolve_timer -= delta
			if dissolve_timer <= 0.0:
				state = GameEnums.EnemyState.RECYCLED
		_:
			pass
	queue_redraw()


func _draw() -> void:
	match state:
		GameEnums.EnemyState.ALIVE:
			var col := Color(0.58, 0.28, 0.52)  # 与玩家轮廓区分
			if is_target:
				col = Color(0.85, 0.65, 0.25)    # 固定靶：土黄色
			if flash_timer > 0.0:
				col = Color(1, 1, 1)
			draw_circle(Vector2.ZERO, radius, Palette.c(col))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Palette.c(Color(0.30, 0.12, 0.28)), 2.0)
		GameEnums.EnemyState.DYING:
			var k := clampf(dissolve_timer / maxf(def.dissolve_time, 0.0001), 0.0, 1.0)
			draw_circle(Vector2.ZERO, radius * (0.6 + 0.4 * k), Palette.c(Color(0.58, 0.28, 0.52, k)))
		_:
			pass
