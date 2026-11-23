extends Node2D

const VIEW_SIZE := Vector2(720.0, 1280.0)
const PLAYER_SPEED := 310.0
const PLAYER_RADIUS := 24.0
const ARENA := Rect2(28.0, 90.0, 664.0, 1110.0)
const JOY_CENTER := Vector2(145.0, 1090.0)
const JOY_RADIUS := 92.0
const SHOOT_CENTER := Vector2(575.0, 1090.0)
const SHOOT_RADIUS := 94.0

class Zombie:
	extends RefCounted
	var pos: Vector2
	var speed: float
	var hp: int
	var radius: float
	var tint: Color
	var phase: float
	func _init(p: Vector2, s: float, h: int, r: float, c: Color, ph: float) -> void:
		pos = p
		speed = s
		hp = h
		radius = r
		tint = c
		phase = ph

var player_pos := Vector2(360.0, 650.0)
var zombies: Array[Zombie] = []
var score: int = 0
var elapsed: float = 0.0
var health: float = 100.0
var spawn_clock: float = 0.0
var fire_clock: float = 0.0
var hurt_clock: float = 0.0
var flash_clock: float = 0.0
var flash_from := Vector2.ZERO
var flash_to := Vector2.ZERO
var game_over: bool = false
var joy_touch: int = -1
var shoot_touch: int = -1
var joy_vector := Vector2.ZERO
var mouse_shoot: bool = false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	queue_redraw()

func _process(delta: float) -> void:
	if game_over:
		queue_redraw()
		return
	elapsed += delta
	spawn_clock -= delta
	fire_clock -= delta
	hurt_clock = maxf(0.0, hurt_clock - delta)
	flash_clock = maxf(0.0, flash_clock - delta)
	if spawn_clock <= 0.0:
		_spawn_zombie()
		spawn_clock = maxf(0.34, 1.35 - elapsed * 0.012) * rng.randf_range(0.78, 1.18)
	var move := joy_vector
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): move.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): move.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move.x += 1.0
	if move.length() > 1.0: move = move.normalized()
	player_pos += move * PLAYER_SPEED * delta
	player_pos.x = clampf(player_pos.x, ARENA.position.x + 30.0, ARENA.end.x - 30.0)
	player_pos.y = clampf(player_pos.y, ARENA.position.y + 36.0, ARENA.end.y - 38.0)
	for z in zombies:
		var toward := player_pos - z.pos
		if toward.length() > 0.001:
			z.pos += toward.normalized() * z.speed * delta
		if hurt_clock <= 0.0 and z.pos.distance_to(player_pos) < z.radius + PLAYER_RADIUS - 5.0:
			health -= 18.0
			hurt_clock = 0.85
			z.pos -= toward.normalized() * 42.0
			if health <= 0.0:
				health = 0.0
				game_over = true
				break
	var firing := Input.is_key_pressed(KEY_SPACE) or mouse_shoot
	if firing and fire_clock <= 0.0 and not zombies.is_empty():
		_shoot_nearest()
		fire_clock = 0.22
	queue_redraw()

func _spawn_zombie() -> void:
	var edge := rng.randi_range(0, 3)
	var p := Vector2.ZERO
	match edge:
		0: p = Vector2(rng.randf_range(ARENA.position.x, ARENA.end.x), ARENA.position.y + 8.0)
		1: p = Vector2(rng.randf_range(ARENA.position.x, ARENA.end.x), ARENA.end.y - 8.0)
		2: p = Vector2(ARENA.position.x + 8.0, rng.randf_range(ARENA.position.y, ARENA.end.y))
		_: p = Vector2(ARENA.end.x - 8.0, rng.randf_range(ARENA.position.y, ARENA.end.y))
	var tier := int(elapsed / 22.0)
	var kind := rng.randi_range(0, 2)
	var speed := rng.randf_range(58.0, 82.0) + minf(float(tier) * 7.0, 45.0)
	var hp := 1
	var radius := 21.0
	var color := Color(0.40, 0.77, 0.39)
	if kind == 1:
		speed *= 1.38
		radius = 17.0
		color = Color(0.63, 0.84, 0.34)
	elif kind == 2:
		speed *= 0.72
		hp = 2 + tier / 3
		radius = 28.0
		color = Color(0.38, 0.58, 0.43)
	zombies.append(Zombie.new(p, speed, hp, radius, color, rng.randf_range(0.0, TAU)))

func _shoot_nearest() -> void:
	var best: Zombie = null
	var best_dist := 1000000.0
	for z in zombies:
		var d := player_pos.distance_squared_to(z.pos)
		if d < best_dist:
			best_dist = d
			best = z
	if best == null: return
	flash_from = player_pos
	flash_to = best.pos
	flash_clock = 0.09
	best.hp -= 1
	if best.hp <= 0:
		zombies.erase(best)
		score += 10

func _screen_to_game(p: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * p

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var p := _screen_to_game(touch.position)
		if touch.pressed:
			if game_over and _restart_rect().has_point(p):
				_restart()
			elif not game_over and p.distance_to(SHOOT_CENTER) <= SHOOT_RADIUS * 1.42:
				shoot_touch = touch.index
			elif not game_over and p.x < 360.0 and p.y > 790.0 and joy_touch == -1:
				joy_touch = touch.index
				_set_joy(p)
		else:
			if touch.index == joy_touch:
				joy_touch = -1
				joy_vector = Vector2.ZERO
			if touch.index == shoot_touch: shoot_touch = -1
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == joy_touch: _set_joy(_screen_to_game(drag.position))
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var p := _screen_to_game(mb.position)
			if game_over and mb.pressed and _restart_rect().has_point(p): _restart()
			else: mouse_shoot = mb.pressed
	elif event is InputEventMouseMotion and joy_touch == -1 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not game_over:
		var mp := _screen_to_game(event.position)
		if mp.distance_to(JOY_CENTER) < JOY_RADIUS * 1.5: _set_joy(mp)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R and game_over:
		_restart()

func _set_joy(p: Vector2) -> void:
	var diff := p - JOY_CENTER
	joy_vector = diff.limit_length(JOY_RADIUS) / JOY_RADIUS

func _restart_rect() -> Rect2:
	return Rect2(210.0, 700.0, 300.0, 92.0)

func _restart() -> void:
	player_pos = Vector2(360.0, 650.0)
	zombies.clear()
	score = 0
	elapsed = 0.0
	health = 100.0
	spawn_clock = 0.0
	fire_clock = 0.0
	hurt_clock = 0.0
	game_over = false
	joy_touch = -1
	shoot_touch = -1
	joy_vector = Vector2.ZERO

func _draw() -> void:
	_draw_arena()
	for z in zombies: _draw_zombie(z)
	_draw_player()
	_draw_hud()
	_draw_controls()
	if flash_clock > 0.0:
		draw_line(flash_from, flash_to, Color(1.0, 0.88, 0.35, flash_clock / 0.09), 5.0, true)
		draw_circle(flash_from + (flash_to - flash_from).normalized() * 37.0, 8.0, Color(1.0, 0.79, 0.28, 0.8))
	if game_over: _draw_game_over()

func _draw_arena() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.035, 0.055, 0.065), true)
	draw_rect(ARENA, Color(0.075, 0.105, 0.105), true)
	for x in range(42, 700, 48):
		for y in range(100, 1200, 48):
			var offset := 24 if int(y / 48) % 2 == 0 else 0
			draw_circle(Vector2(float(x + offset), float(y)), 1.5, Color(0.16, 0.21, 0.20, 0.42))
	draw_rect(ARENA, Color(0.30, 0.48, 0.40, 0.65), false, 3.0)
	for i in range(8):
		var bx := 75.0 + float(i) * 82.0
		draw_rect(Rect2(bx, 136.0, 31.0, 12.0), Color(0.24, 0.31, 0.28), true)

func _draw_player() -> void:
	if hurt_clock > 0.0 and int(hurt_clock * 14.0) % 2 == 0: return
	draw_circle(player_pos + Vector2(0, 6), 27.0, Color(0.0, 0.0, 0.0, 0.28))
	draw_circle(player_pos, PLAYER_RADIUS, Color(0.20, 0.67, 0.88))
	draw_circle(player_pos + Vector2(-6, -6), 8.0, Color(0.55, 0.88, 0.96))
	draw_circle(player_pos + Vector2(7, -5), 3.0, Color.WHITE)
	draw_rect(Rect2(player_pos + Vector2(17, -7), Vector2(23, 14)), Color(0.68, 0.74, 0.73), true)
	draw_rect(Rect2(player_pos + Vector2(34, -4), Vector2(8, 8)), Color(1.0, 0.77, 0.35), true)

func _draw_zombie(z: Zombie) -> void:
	var wobble := sin(elapsed * 7.0 + z.phase) * 2.0
	draw_circle(z.pos + Vector2(0, 5), z.radius + 2.0, Color(0.0, 0.0, 0.0, 0.23))
	draw_circle(z.pos + Vector2(wobble, 0), z.radius, z.tint)
	draw_circle(z.pos + Vector2(-z.radius * 0.28, -3), 3.0, Color(0.95, 0.23, 0.18))
	draw_circle(z.pos + Vector2(z.radius * 0.25, -3), 3.0, Color(0.95, 0.23, 0.18))
	draw_line(z.pos + Vector2(-6, 8), z.pos + Vector2(7, 7), Color(0.15, 0.20, 0.16), 3.0)
	if z.hp > 1:
		draw_rect(Rect2(z.pos + Vector2(-z.radius, -z.radius - 9), Vector2(z.radius * 2.0, 4.0)), Color(0.12, 0.15, 0.13), true)
		draw_rect(Rect2(z.pos + Vector2(-z.radius, -z.radius - 9), Vector2(z.radius * 2.0 * float(z.hp) / float(2 + int(elapsed / 66.0)), 4.0)), Color(0.94, 0.53, 0.26), true)

func _draw_hud() -> void:
	draw_rect(Rect2(0, 0, 720, 82), Color(0.025, 0.04, 0.048, 0.96), true)
	draw_string(ThemeDB.fallback_font, Vector2(28, 42), "ZOMBIE ARENA", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.79, 0.93, 0.87))
	draw_string(ThemeDB.fallback_font, Vector2(30, 68), "SCORE  %05d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.99, 0.76, 0.36))
	draw_string(ThemeDB.fallback_font, Vector2(500, 39), "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color(0.87, 0.92, 0.88))
	draw_string(ThemeDB.fallback_font, Vector2(500, 66), "WAVE %02d" % (1 + int(elapsed / 22.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.52, 0.78, 0.69))
	draw_rect(Rect2(28, 94, 230, 16), Color(0.15, 0.18, 0.17), true)
	draw_rect(Rect2(28, 94, 230.0 * health / 100.0, 16), Color(0.25, 0.82, 0.48) if health > 35 else Color(0.94, 0.30, 0.23), true)
	draw_string(ThemeDB.fallback_font, Vector2(270, 108), "HEALTH", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.74, 0.82, 0.77))

func _draw_controls() -> void:
	draw_circle(JOY_CENTER, JOY_RADIUS, Color(0.08, 0.13, 0.14, 0.54))
	draw_arc(JOY_CENTER, JOY_RADIUS, 0.0, TAU, 64, Color(0.48, 0.65, 0.63, 0.65), 3.0)
	draw_circle(JOY_CENTER + joy_vector * (JOY_RADIUS * 0.57), 39.0, Color(0.44, 0.64, 0.64, 0.72))
	draw_circle(SHOOT_CENTER, SHOOT_RADIUS, Color(0.50, 0.12, 0.12, 0.55))
	draw_arc(SHOOT_CENTER, SHOOT_RADIUS, 0.0, TAU, 64, Color(1.0, 0.42, 0.30, 0.85), 4.0)
	draw_circle(SHOOT_CENTER, 64.0, Color(0.83, 0.22, 0.16, 0.88) if shoot_touch != -1 or mouse_shoot or Input.is_key_pressed(KEY_SPACE) else Color(0.67, 0.19, 0.15, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(514, 1099), "SHOOT", HORIZONTAL_ALIGNMENT_CENTER, 122, 23, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(360, 1228), "MOVE                         AUTO-AIM", HORIZONTAL_ALIGNMENT_CENTER, 300, 15, Color(0.67, 0.76, 0.72, 0.85))

func _draw_game_over() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.01, 0.02, 0.025, 0.78), true)
	draw_string(ThemeDB.fallback_font, Vector2(360, 540), "YOU WERE OVERRUN", HORIZONTAL_ALIGNMENT_CENTER, 600, 42, Color(1.0, 0.39, 0.30))
	draw_string(ThemeDB.fallback_font, Vector2(360, 605), "FINAL SCORE  %05d" % score, HORIZONTAL_ALIGNMENT_CENTER, 500, 26, Color(0.96, 0.90, 0.72))
	draw_string(ThemeDB.fallback_font, Vector2(360, 648), "SURVIVED  %d SECONDS" % int(elapsed), HORIZONTAL_ALIGNMENT_CENTER, 500, 20, Color(0.72, 0.81, 0.77))
	draw_rect(_restart_rect(), Color(0.20, 0.67, 0.49), true, 14.0)
	draw_string(ThemeDB.fallback_font, Vector2(360, 758), "PLAY AGAIN", HORIZONTAL_ALIGNMENT_CENTER, 270, 25, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(360, 825), "Tap button  •  R to restart", HORIZONTAL_ALIGNMENT_CENTER, 400, 17, Color(0.76, 0.82, 0.78))
