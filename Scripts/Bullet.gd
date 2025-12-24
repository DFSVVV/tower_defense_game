extends CharacterBody2D
class_name BaseBullet

var target
var speed
var bulletDamage
var target_enemy: CharacterBody2D

func set_target(new_target):
	target_enemy = new_target
	
func _physics_process(delta):
	if not is_instance_valid(target_enemy):
		queue_free()
		return
		
	var target_pos = target_enemy.global_position
	
	velocity = global_position.direction_to(target_pos) * speed
	look_at(target_pos)
	move_and_slide()

func _on_collision_body_entered(body):
	if body is BaseEnemy:
		body.health -= bulletDamage
		queue_free()
		
