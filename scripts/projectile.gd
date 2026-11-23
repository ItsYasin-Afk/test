extends Area2D

var direction: Vector2 = Vector2.RIGHT
var damage: float = 20.0
var speed: float = 780.0
var lifetime: float = 1.2
var explosive: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	queue_redraw()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	for zombie in get_tree().get_nodes_in_group("zombies"):
		if not is_instance_valid(zombie):
			continue
		if global_position.distance_to(zombie.global_position) < (43.0 if explosive else 22.0):
			if explosive:
				for nearby in get_tree().get_nodes_in_group("zombies"):
					if is_instance_valid(nearby) and global_position.distance_to(nearby.global_position) < 115.0:
						nearby.call("take_hit", damage)
			else:
				zombie.call("take_hit", damage)
			get_tree().call_group("game", "spawn_impact", global_position)
			queue_free()
			return
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0 if not explosive else 8.0, Color(1.0, 0.76, 0.34))
