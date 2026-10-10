class_name Player
extends Node2D
## 玩家实体。逻辑由 Arena._step 驱动（tick），占位图形自绘（开发方案 4.3）。

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


func setup(d: PlayerDef) -> void:
	def = d
	max_hp = d.max_hp
	hp = d.max_hp
	move_speed = d.move_speed
	radius = d.body_radius
	pickup_radius = d.xp_pickup_radius


func tick(delta: float) -> void:
	if iframe_timer > 0.0:
		iframe_timer = maxf(0.0, iframe_timer - delta)
		flicker_time += delta
	if flash_timer > 0.0:
		flash_timer = maxf(0.0, flash_timer - delta)
	# 无输入立即停止，无惯性；输入框持有焦点时不移动（设计文档 4.1 / 8.2）
	if not lock_position and not Game.ui_has_focus():
		var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		position += v * move_speed * delta
	queue_redraw()


func try_take_contact_damage(amount: int) -> bool:
	## 接触伤害入口：受无敌时间限制；同时接触多个敌人只接受一次（验收 A04）
	if hp <= 0 or invincible or iframe_timer > 0.0:
		return false
	hp = maxi(0, hp - amount)
	iframe_timer = def.contact_iframes
	flash_timer = 0.1
	EventBus.player_damaged.emit(amount, hp)
	return true


func _draw() -> void:
	var alpha := 1.0
	if iframe_timer > 0.0 and fmod(flicker_time, 0.24) < 0.12:
		alpha = 0.45  # 无敌期低频透明度变化（设计文档 4.3）
	draw_circle(Vector2.ZERO, radius, Palette.c(Color(0.96, 0.90, 0.80, alpha)))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Palette.c(Color(0.85, 0.35, 0.30, alpha)), 3.0)
	if flash_timer > 0.0:
		draw_circle(Vector2.ZERO, radius + 2.0, Palette.c(Color(1, 1, 1, 0.75)))
