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
var sprite: Sprite2D
var art_material: ShaderMaterial
var visual_time := 0.0


func _ready() -> void:
	z_index = 5
	GameArt.apply_world_material(self)
	sprite = Sprite2D.new()
	sprite.texture = GameArt.trimmed(GameArt.TARGET if is_target else GameArt.ENEMY)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art_material = GameArt.actor_material()
	sprite.material = art_material
	add_child(sprite)
	_sync_sprite()


func setup(d: EnemyDef, spawn_id: int, speed: float, p: Player) -> void:
	def = d
	id = spawn_id
	hp = d.max_hp
	radius = d.body_radius
	chase_speed = speed
	player = p


func tick(delta: float) -> void:
	visual_time += delta
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
	_sync_sprite()
	queue_redraw()


func _sync_sprite() -> void:
	if sprite == null:
		return
	var life := 1.0
	if state == GameEnums.EnemyState.DYING:
		life = clampf(dissolve_timer / maxf(def.dissolve_time, 0.001), 0.0, 1.0)
	sprite.visible = state != GameEnums.EnemyState.RECYCLED
	var height := 56.0 if is_target else 44.0
	var size := height / sprite.texture.get_height()
	var phase := visual_time * 6.0 + float(id) * 1.7
	var bounce := 0.0 if is_target or chase_speed <= 0.0 else absf(sin(phase)) * 1.2
	var hit := clampf(flash_timer / maxf(def.hit_flash_time, 0.001), 0.0, 1.0)
	sprite.position = Vector2(0, -13.0 - bounce + (1.0 - life) * 5.0)
	sprite.scale = Vector2(size * (1.0 + hit * 0.10), size * (0.7 + life * 0.3 - hit * 0.07))
	sprite.modulate = Color(1, 1, 1, life)
	sprite.rotation = sin(phase) * 0.025 if not is_target else hit * 0.05
	if not is_target and player != null:
		sprite.flip_h = player.position.x > position.x
	art_material.set_shader_parameter("hit_flash", hit * 0.9)


func _draw() -> void:
	if state == GameEnums.EnemyState.RECYCLED:
		return
	var life := 1.0
	if state == GameEnums.EnemyState.DYING:
		life = clampf(dissolve_timer / maxf(def.dissolve_time, 0.001), 0.0, 1.0)
	draw_set_transform(Vector2(0, 7), 0.0, Vector2(1.3, 0.35))
	draw_circle(Vector2.ZERO, radius, Palette.c(Color(0.02, 0.02, 0.025, 0.32 * life)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == GameEnums.EnemyState.DYING:
		for i in 5:
			var dir := Vector2.from_angle(float(i) * TAU / 5.0 + float(id))
			draw_circle(dir * (5.0 + 15.0 * (1.0 - life)) + Vector2(0, -8),
					1.5 * life, Palette.c(Color(1.0, 0.55, 0.16, life * 0.7)))
	elif not is_target and hp < def.max_hp:
		draw_rect(Rect2(-13, -39, 26, 3), Palette.c(Color(0.08, 0.07, 0.07, 0.8)))
		draw_rect(Rect2(-13, -39, 26.0 * hp / def.max_hp, 3),
				Palette.c(Color(0.92, 0.35, 0.3)))
