extends CharacterBody2D
class_name ZombieActor

signal killed(points: int)

var target: Node2D
var zombie_type: String = "Normal"
var health: float = 40.0
var speed: float = 72.0
var contact_damage: float = 10.0
var score_value: int = 10
var attack_cooldown: float = 0.0
var tint: Color = Color(0.35, 0.62, 0.32)

func configure(kind: String, wave: int) -> void:
	zombie_type = kind
	match kind:
		"Runner":
			health = 25.0 + wave * 3.0
			speed = 125.0 + wave * 1.5
			contact_damage = 7.0
			score_value = 15
			tint = Color(0.72, 0.78, 0.31)
		"Heavy":
			health = 130.0 + wave * 12.0
			speed = 42.0 + wave * 0.6
			contact_damage = 22.0
			score_value = 35
			tint = Color(0.42, 0.46, 0.48)
		"Boss":
			health = 650.0 + wave * 55.0
			speed = 54.0 + wave * 0.7
			contact_damage = 30.0
			score_value = 250
			tint = Color(0.62, 0.22, 0.26)
		_:
			health = 45.0 + wave * 5.0
			speed = 68.0 + wave * 1.0
			contact_damage = 11.0
			score_value = 10
	add_to_group("zombies")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * speed
	move_and_slide()
	if global_position.distance_to(target.global_position) < 30.0 and attack_cooldown <= 0.0:
		if target.has_method("take_damage"):
			target.call("take_damage", contact_damage)
		attack_cooldown = 0.85
	queue_redraw()

func take_hit(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		killed.emit(score_value)
		get_tree().call_group("game", "on_zombie_killed", global_position, score_value)
		queue_free()

func _draw() -> void:
	var radius := 16.0
	if zombie_type == "Heavy":
		radius = 22.0
	elif zombie_type == "Boss":
		radius = 34.0
	draw_circle(Vector2.ZERO, radius + 3.0, Color(0.02, 0.025, 0.02, 0.8))
	draw_circle(Vector2.ZERO, radius, tint)
	draw_circle(Vector2(-5.0, -4.0), 3.0, Color(0.95, 0.3, 0.2))
	draw_circle(Vector2(5.0, -4.0), 3.0, Color(0.95, 0.3, 0.2))
	if zombie_type == "Boss":
		draw_arc(Vector2.ZERO, radius + 7.0, 0.0, TAU, 48, Color(1.0, 0.35, 0.25), 3.0)
