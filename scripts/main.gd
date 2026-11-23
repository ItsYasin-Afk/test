extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const ZOMBIE_SCRIPT = preload("res://scripts/zombie.gd")
const HUD_SCRIPT = preload("res://scripts/hud.gd")

var player: PlayerActor
var hud: GameHUD
var wave: int = 1
var score: int = 0
var alive_to_spawn: int = 0
var spawn_timer: float = 0.0
var between_waves: bool = false
var shake_strength: float = 0.0
var camera_offset: Vector2 = Vector2.ZERO
var arena_size: Vector2 = Vector2(720, 1280)
var particles: Array[Dictionary] = []
var game_camera: Camera2D

func _ready() -> void:
	add_to_group("game")
	randomize()
	_create_world()
	_create_player()
	_create_hud()
	_start_wave()

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if alive_to_spawn > 0 and not between_waves:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			_spawn_zombie()
			alive_to_spawn -= 1
			spawn_timer = maxf(0.25, 1.15 - wave * 0.035)
	if alive_to_spawn == 0 and get_tree().get_nodes_in_group("zombies").is_empty() and not between_waves:
		_finish_wave()
	_update_particles(delta)
	shake_strength = maxf(0.0, shake_strength - delta * 28.0)
	if is_instance_valid(game_camera):
		game_camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(hud):
		var move_value := hud.move_stick.get_value()
		var aim_value := hud.aim_stick.get_value()
		player.set_controls(move_value, aim_value)
		if aim_value.length() > 0.15:
			player.try_fire(aim_value)

func _create_world() -> void:
	game_camera = Camera2D.new()
	game_camera.position = arena_size * 0.5
	game_camera.enabled = true
	add_child(game_camera)

func _create_player() -> void:
	player = PlayerActor.new()
	player.position = arena_size * 0.5
	player.z_index = 5
	add_child(player)
	player.health_changed.connect(func(current: float, maximum: float) -> void:
		if is_instance_valid(hud):
			hud.set_health(current, maximum)
	)
	player.ammo_changed.connect(_on_ammo_changed)
	player.died.connect(_on_player_died)

func _create_hud() -> void:
	hud = GameHUD.new()
	add_child(hud)
	hud.reload_pressed.connect(func() -> void: player.reload())
	hud.weapon_pressed.connect(func() -> void: player.switch_weapon((player.weapon_index + 1) % player.weapons.size()))
	hud.upgrade_selected.connect(_on_upgrade_selected)
	hud.set_health(player.health, player.max_health)
	hud.set_ammo(player.ammo, player.reserve_ammo, str(player.weapons[player.weapon_index]["name"]))
	hud.set_wave(wave)
	hud.set_score(score)

func _start_wave() -> void:
	between_waves = false
	alive_to_spawn = 5 + wave * 2
	spawn_timer = 1.0
	hud.set_wave(wave)
	hud.show_message("WAVE %d INCOMING" % wave)

func _spawn_zombie() -> void:
	var zombie := ZombieActor.new()
	var edge := randi_range(0, 3)
	match edge:
		0:
			zombie.position = Vector2(randf_range(30.0, 690.0), -35.0)
		1:
			zombie.position = Vector2(randf_range(30.0, 690.0), 1315.0)
		2:
			zombie.position = Vector2(-35.0, randf_range(30.0, 1250.0))
		_:
			zombie.position = Vector2(755.0, randf_range(30.0, 1250.0))
	zombie.target = player
	var kind := "Normal"
	var roll := randf()
	if wave % 5 == 0 and alive_to_spawn == 0:
		kind = "Boss"
	elif roll < 0.18:
		kind = "Runner"
	elif roll < 0.30:
		kind = "Heavy"
	zombie.configure(kind, wave)
	add_child(zombie)

func _finish_wave() -> void:
	between_waves = true
	hud.show_message("WAVE CLEARED")
	hud.show_upgrades()

func _on_upgrade_selected(upgrade_name: String) -> void:
	player.apply_upgrade(upgrade_name)
	wave += 1
	_start_wave()

func _on_ammo_changed(current: int, reserve: int) -> void:
	if is_instance_valid(hud):
		hud.set_ammo(current, reserve, str(player.weapons[player.weapon_index]["name"]))

func _on_player_died() -> void:
	hud.show_message("RUN ENDED")
	hud.show_game_over()
	between_waves = true
	alive_to_spawn = 0

func on_player_fired() -> void:
	shake_strength = maxf(shake_strength, 1.5)

func on_player_hurt() -> void:
	shake_strength = 9.0

func on_zombie_killed(at_position: Vector2, points: int) -> void:
	score += points
	hud.set_score(score)
	spawn_impact(at_position)

func spawn_impact(at_position: Vector2) -> void:
	for i in range(7):
		particles.append({
			"position": at_position,
			"velocity": Vector2.from_angle(randf() * TAU) * randf_range(25.0, 115.0),
			"life": randf_range(0.18, 0.48),
			"size": randf_range(2.0, 5.0)
		})

func _update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[i]
		particle["life"] = float(particle["life"]) - delta
		particle["position"] = particle["position"] + particle["velocity"] * delta
		particle["velocity"] = particle["velocity"] * 0.88
		if float(particle["life"]) <= 0.0:
			particles.remove_at(i)
		else:
			particles[i] = particle

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, arena_size), Color(0.07, 0.09, 0.1), true)
	for x in range(0, 721, 64):
		draw_line(Vector2(x, 0), Vector2(x, 1280), Color(0.12, 0.15, 0.16), 1.0)
	for y in range(0, 1281, 64):
		draw_line(Vector2(0, y), Vector2(720, y), Color(0.12, 0.15, 0.16), 1.0)
	for particle in particles:
		var alpha := clampf(float(particle["life"]) * 2.5, 0.0, 1.0)
		var color := Color(0.72, 0.22, 0.16, alpha)
		draw_circle(particle["position"], float(particle["size"]), color)
