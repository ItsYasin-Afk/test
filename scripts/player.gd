extends CharacterBody2D
class_name PlayerActor

signal health_changed(current: float, maximum: float)
signal ammo_changed(current: int, reserve: int)
signal died

@export var move_speed: float = 245.0
@export var max_health: float = 100.0
@export var damage: float = 22.0
@export var fire_interval: float = 0.22

var health: float = 100.0
var invulnerability_left: float = 0.0
var fire_cooldown: float = 0.0
var reload_left: float = 0.0
var weapon_index: int = 0
var ammo: int = 18
var reserve_ammo: int = 120
var movement_input: Vector2 = Vector2.ZERO
var aim_input: Vector2 = Vector2.RIGHT
var aim_target: Vector2 = Vector2.RIGHT
var is_reloading: bool = false
var weapons: Array[Dictionary] = [
	{"name": "Pistol", "mag": 18, "reserve": 120, "interval": 0.22, "damage": 22.0, "pellets": 1, "spread": 0.0, "reload": 1.1},
	{"name": "Shotgun", "mag": 6, "reserve": 42, "interval": 0.75, "damage": 13.0, "pellets": 6, "spread": 0.38, "reload": 1.5},
	{"name": "SMG", "mag": 32, "reserve": 200, "interval": 0.075, "damage": 9.0, "pellets": 1, "spread": 0.08, "reload": 1.3},
	{"name": "Launcher", "mag": 3, "reserve": 18, "interval": 0.9, "damage": 70.0, "pellets": 1, "spread": 0.0, "reload": 1.8}
]

func _ready() -> void:
	health = max_health
	ammo = int(weapons[weapon_index]["mag"])
	reserve_ammo = int(weapons[weapon_index]["reserve"])
	add_to_group("player")
	health_changed.emit(health, max_health)
	ammo_changed.emit(ammo, reserve_ammo)

func _physics_process(delta: float) -> void:
	invulnerability_left = maxf(0.0, invulnerability_left - delta)
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if is_reloading:
		reload_left -= delta
		if reload_left <= 0.0:
			_finish_reload()
	if not OS.has_feature("mobile"):
		var mouse_direction := global_position.direction_to(get_global_mouse_position())
		if mouse_direction.length() > 0.1:
			aim_input = mouse_direction
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_vector := movement_input if movement_input.length() > 0.08 else keyboard
	velocity = move_vector.limit_length() * move_speed
	move_and_slide()
	if Input.is_action_just_pressed("weapon_next"):
		switch_weapon((weapon_index + 1) % weapons.size())
	if Input.is_action_just_pressed("reload"):
		reload()
	if Input.is_action_pressed("fire") and aim_input.length() > 0.1:
		try_fire(aim_input)

func set_controls(move_value: Vector2, aim_value: Vector2) -> void:
	movement_input = move_value
	if aim_value.length() > 0.16:
		aim_input = aim_value.normalized()
		aim_target = aim_input

func try_fire(direction: Vector2) -> void:
	if fire_cooldown > 0.0 or is_reloading:
		return
	if ammo <= 0:
		reload()
		return
	var data: Dictionary = weapons[weapon_index]
	fire_cooldown = float(data["interval"])
	ammo -= 1
	ammo_changed.emit(ammo, reserve_ammo)
	var base_direction := _assist_aim(direction.normalized())
	var pellets := int(data["pellets"])
	for i in range(pellets):
		var spread := float(data["spread"])
		var angle := randf_range(-spread, spread)
		var shot_direction := base_direction.rotated(angle)
		var projectile := Area2D.new()
		projectile.set_script(load("res://scripts/projectile.gd"))
		projectile.global_position = global_position + shot_direction * 26.0
		projectile.set("direction", shot_direction)
		projectile.set("damage", float(data["damage"]) * damage / 22.0)
		projectile.set("explosive", weapon_index == 3)
		get_tree().current_scene.add_child(projectile)
	get_tree().call_group("game", "on_player_fired")

func _assist_aim(direction: Vector2) -> Vector2:
	var best: Node2D = null
	var best_score: float = 0.0
	for candidate in get_tree().get_nodes_in_group("zombies"):
		if not is_instance_valid(candidate):
			continue
		var offset: Vector2 = candidate.global_position - global_position
		var distance := offset.length()
		if distance > 430.0 or distance < 1.0:
			continue
		var alignment := direction.dot(offset.normalized())
		if alignment > 0.78:
			var score := alignment - distance / 1800.0
			if score > best_score:
				best_score = score
				best = candidate
	if best != null:
		return global_position.direction_to(best.global_position)
	return direction

func take_damage(amount: float) -> void:
	if invulnerability_left > 0.0 or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	invulnerability_left = 0.72
	health_changed.emit(health, max_health)
	get_tree().call_group("game", "on_player_hurt")
	if health <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)

func apply_upgrade(upgrade_name: String) -> void:
	match upgrade_name:
		"Speed":
			move_speed += 18.0
		"Health":
			max_health += 20.0
			heal(20.0)
		"Damage":
			damage *= 1.18
		"Fire Rate":
			fire_interval = maxf(0.055, fire_interval * 0.88)
			for item in weapons:
				item["interval"] = maxf(0.055, float(item["interval"]) * 0.88)

func switch_weapon(next_index: int) -> void:
	if next_index < 0 or next_index >= weapons.size() or next_index == weapon_index:
		return
	weapon_index = next_index
	ammo = int(weapons[weapon_index]["mag"])
	reserve_ammo = int(weapons[weapon_index]["reserve"])
	is_reloading = false
	ammo_changed.emit(ammo, reserve_ammo)

func reload() -> void:
	if is_reloading or ammo >= int(weapons[weapon_index]["mag"]) or reserve_ammo <= 0:
		return
	is_reloading = true
	reload_left = float(weapons[weapon_index]["reload"])

func _finish_reload() -> void:
	var magazine_size := int(weapons[weapon_index]["mag"])
	var needed := magazine_size - ammo
	var loaded := mini(needed, reserve_ammo)
	ammo += loaded
	reserve_ammo -= loaded
	is_reloading = false
	ammo_changed.emit(ammo, reserve_ammo)

func _draw() -> void:
	var body_color := Color(0.24, 0.72, 0.82)
	if invulnerability_left > 0.0 and int(Time.get_ticks_msec() / 90) % 2 == 0:
		body_color.a = 0.35
	draw_circle(Vector2.ZERO, 19.0, Color(0.015, 0.025, 0.03))
	draw_circle(Vector2.ZERO, 15.0, body_color)
	draw_circle(Vector2(4.0, -4.0), 5.0, Color(0.85, 0.95, 0.95))
	var facing := aim_input.normalized() if aim_input.length() > 0.1 else Vector2.RIGHT
	draw_line(facing * 9.0, facing * 29.0, Color(0.9, 0.78, 0.48), 6.0)
