class_name Player
extends Node2D
## 玩家实体。逻辑与贴图动画均由 Arena._step 驱动，暂停与慢放共用同一时钟。

var def: PlayerDef
var hp: int
var max_hp: int
var move_speed: float
var radius: float
var pickup_radius: float
var iframe_timer := 0.0   # 接触无敌剩余
var flash_timer := 0.0    # 受击闪白剩余
var flicker_time := 0.0   # 无敌期闪烁累计
var invincible := false   # 仅试验模式（设计文档 4.3）
var lock_position := false  # 仅试验模式
var sprite: Sprite2D
var art_material: ShaderMaterial
var visual_time := 0.0
var walk_time := 0.0
var cast_timer := 0.0
var facing_left := false
var moving := false


func _ready() -> void:
	z_index = 10
	GameArt.apply_world_material(self)
	sprite = Sprite2D.new()
	sprite.texture = GameArt.trimmed(GameArt.PLAYER)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art_material = GameArt.actor_material()
	sprite.material = art_material
	add_child(sprite)
	EventBus.attack_fired.connect(_on_attack_fired)
	_sync_sprite()


func setup(d: PlayerDef) -> void:
	def = d
	max_hp = d.max_hp
	hp = d.max_hp
	move_speed = d.move_speed
	radius = d.body_radius
	pickup_radius = d.xp_pickup_radius


func tick(delta: float) -> void:
	visual_time += delta
	cast_timer = maxf(0.0, cast_timer - delta)
	if iframe_timer > 0.0:
		iframe_timer = maxf(0.0, iframe_timer - delta)
		flicker_time += delta
	if flash_timer > 0.0:
		flash_timer = maxf(0.0, flash_timer - delta)
	# 无输入立即停止，无惯性；输入框持有焦点时不移动（设计文档 4.1 / 8.2）
	moving = false
	if not lock_position and not Game.ui_has_focus():
		var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		position += v * move_speed * delta
		moving = v.length_squared() > 0.001
		if moving:
			walk_time += delta * 12.0
			if absf(v.x) > 0.01 and cast_timer <= 0.0:
				facing_left = v.x < 0.0
	_sync_sprite()
	queue_redraw()


func try_take_contact_damage(amount: int) -> bool:
	## 接触伤害入口：受无敌时间限制；同时接触多个敌人只接受一次（验收 A04）
	if hp <= 0 or invincible or iframe_timer > 0.0:
		return false
	hp = maxi(0, hp - amount)
	iframe_timer = def.contact_iframes
	flash_timer = 0.1
	_sync_sprite()
	EventBus.player_damaged.emit(amount, hp)
	return true


func _on_attack_fired(_element: int, _id: int, pos: Vector2, dir: Vector2) -> void:
	if not is_inside_tree() or pos.distance_squared_to(position) > 1.0:
		return
	cast_timer = 0.18
	if absf(dir.x) > 0.01:
		facing_left = dir.x < 0.0
	_sync_sprite()


func _sync_sprite() -> void:
	if sprite == null:
		return
	var alpha := 1.0
	if iframe_timer > 0.0 and fmod(flicker_time, 0.24) < 0.12:
		alpha = 0.45  # 无敌期低频透明度变化（设计文档 4.3）
	var step_bob := absf(sin(walk_time)) * 1.8 if moving else sin(visual_time * 2.4) * 0.4
	var cast := sin(clampf(cast_timer / 0.18, 0.0, 1.0) * PI)
	var size := 68.0 / sprite.texture.get_height()
	sprite.scale = Vector2(size * (1.0 + cast * 0.055), size * (1.0 - cast * 0.035))
	sprite.position = Vector2(-2.0, -19.0 - step_bob)
	sprite.rotation = sin(walk_time) * 0.035 if moving else 0.0
	sprite.flip_h = facing_left
	sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	art_material.set_shader_parameter("hit_flash", 0.85 if flash_timer > 0.0 else 0.0)


func _draw() -> void:
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.45, 0.38))
	draw_circle(Vector2.ZERO, radius, Palette.c(Color(0.02, 0.025, 0.025, 0.38)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_arc(Vector2(0, 5), radius + 2.0, 0.15, PI - 0.15, 20,
			Palette.c(Color(0.35, 0.85, 0.77, 0.6)), 1.5, true)
