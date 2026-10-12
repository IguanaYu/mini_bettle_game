extends Node
## Render the actual game and check paused/grayscale raster art and real UI input.

var main_scene: Node
var failed := 0
var output := "res://docs/screenshots/fire_v01/"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	main_scene = load("res://scenes/main.tscn").instantiate()
	add_child(main_scene)
	await _present()
	Game.enter_experiment()
	await _present()
	var ctl: ExperimentController = main_scene.experiment
	var arena: Arena = main_scene.arena
	_check("experiment panel stays inside the viewport", ctl.panel.root_panel.get_global_rect().end.x
			<= get_viewport().get_visible_rect().end.x)
	await _click(ctl.panel.preset_buttons[1])
	var targets_fit := true
	for enemy in arena.enemies:
		var rect: Rect2 = enemy.sprite.get_global_transform_with_canvas() * enemy.sprite.get_rect()
		targets_fit = targets_fit and (rect.end.x < ctl.panel.root_panel.get_global_rect().position.x
				and rect.position.y >= 24.0 and rect.end.y <= 696.0)
	_check("all target artwork clears the walls and experiment panel", targets_fit)
	await _click(ctl.panel.preset_buttons[0])
	arena.step_manual(0.0)
	ctl.single_fire()
	_step(arena, 15)
	await _shot("01_fireball_flight")
	_step(arena, 20)
	await _shot("02_fireball_hit")
	ctl.set_visual(GameEnums.VisualVersion.B)
	ctl.reset_world()
	await _present()
	ctl.single_fire()
	_step(arena, 15)
	await _shot("03_fireball_b")
	ctl.set_playback(GameEnums.PlaybackRate.PAUSED)
	await _present()
	var frozen := _world_hash()
	await get_tree().create_timer(0.2).timeout
	await _present()
	_check("paused world pixels stay identical", _world_hash() == frozen)
	await _click(ctl.panel.gray_check)
	await _shot("04_grayscale_paused")
	_check("all world artwork is grayscale while paused", _colored_world_pixels() == 0)
	await _click(ctl.panel.gray_check)
	await _click(ctl.panel.dark_check)
	await _shot("05_dark_paused")
	_check("color returns while paused", _colored_world_pixels() > 100)
	await _click(ctl.panel.dark_check)
	ctl.set_playback(GameEnums.PlaybackRate.NORMAL_1)
	await _click(ctl.panel.weapon_buttons[1])
	_check("real click selects scatter", ctl.fire_weapon == GameEnums.FireWeapon.SCATTER)
	ctl.single_fire()
	_step(arena, 13)
	await _shot("06_scatter")
	await _click(ctl.panel.weapon_buttons[2])
	_check("real click selects fire egg", ctl.fire_weapon == GameEnums.FireWeapon.FIRE_EGG)
	ctl.single_fire()
	_step(arena, 60)
	await _shot("07_fire_egg")
	_step(arena, 48)
	await _shot("08_fire_pool")
	_check("fire egg produces a visible pool", arena.fire_eggs.pools.size() == 1)
	ctl.panel.rule_spins[0].value = 9
	_check("fire egg UI adjusts pool damage", arena.fire_eggs.rule.pool_damage == 9.0)
	ctl.set_auto_fire(true)
	ctl.set_fire_weapon(GameEnums.FireWeapon.SCATTER)
	_step(arena, 1)
	_check("continuous scatter does not also fire the default weapon", arena.projectiles.balls.size() == 3)
	ctl.reset_world()
	_step(arena, 60)
	_check("reset keeps selected weapon and continuous fire", ctl.fire_weapon == GameEnums.FireWeapon.SCATTER
			and arena.projectiles.balls.size() > 0 and arena.fire_eggs.eggs.is_empty())
	ctl.set_auto_fire(false)
	ctl.reset_world()
	await _present()
	_check("reset removes all transient artwork", arena.fx_layer.fx_count() == 0
			and arena.projectiles.balls.is_empty() and arena.fire_eggs.pools.is_empty())
	await _combat_shot()
	Game.return_to_menu()
	await _present()
	_check("exit restores color and time scale", not Palette.grayscale and Engine.time_scale == 1.0)
	print("[fire-art] finished, failures=", failed)
	get_tree().quit(0 if failed == 0 else 1)


func _combat_shot() -> void:
	Game.return_to_menu()
	await _present()
	Game.start_run()
	await _present()
	var arena: Arena = main_scene.arena
	arena.spawner.enabled = false
	arena.projectiles.auto_fire = false
	arena.player.position = Vector2(-100, 20)
	arena.player.invincible = true
	arena.step_manual(0.0)
	for i in 18:
		var angle := float(i) * TAU / 18.0
		var pos := Vector2.from_angle(angle) * (160.0 + float(i % 3) * 30.0)
		var enemy := arena.spawn_target(pos, false)
		enemy.chase_speed = 60.0
	for pos in [Vector2(-175, 110), Vector2(-150, 125), Vector2(-50, 130), Vector2(60, 100)]:
		arena.xp_manager.spawn_gem(pos, 5)
	arena.fire_eggs._spawn_pool(Vector2(140, 90), arena.fire_egg_rule_base)
	arena.projectiles.current_visual = arena.visual_b
	arena.projectiles.fire_at(arena.enemies[0])
	arena.scatter.fire_volley(arena.enemies[1])
	_step(arena, 15)
	await _shot("09_survival_combat")
	# Exercise movement through the game's existing input actions.
	var previous := arena.player.position
	Input.action_press("move_left")
	_step(arena, 18)
	Input.action_release("move_left")
	_check("movement still updates sprite facing and position", arena.player.position.x < previous.x
			and arena.player.facing_left)
	await _shot("10_survival_moved")


func _step(arena: Arena, frames: int) -> void:
	for i in frames:
		arena.step_manual(1.0 / 60.0)


func _present() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _shot(name: String) -> void:
	await _present()
	var file := output + name + ".png"
	var result := get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(file))
	_check("saved " + name, result == OK)


func _world_image() -> Image:
	var panel: ExperimentPanel = main_scene.experiment.panel
	var width := int(panel.root_panel.get_global_rect().position.x) - 36
	return get_viewport().get_texture().get_image().get_region(Rect2i(28, 28, width, 662))


func _world_hash() -> int:
	return hash(_world_image().get_data())


func _colored_world_pixels() -> int:
	var image := _world_image()
	var colored := 0
	for y in range(0, image.get_height(), 3):
		for x in range(0, image.get_width(), 3):
			var pixel := image.get_pixel(x, y)
			if maxf(absf(pixel.r - pixel.g), absf(pixel.g - pixel.b)) > 0.012:
				colored += 1
	return colored


func _click(control: Control) -> void:
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(control)
			break
		parent = parent.get_parent()
	await _present()
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	await _present()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = point
	press.pressed = true
	Input.parse_input_event(press)
	await _present()
	var release: InputEventMouseButton = press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await _present()


func _check(name: String, passed: bool) -> void:
	if not passed:
		failed += 1
	print("[fire-art] ", "PASS " if passed else "FAIL ", name)
