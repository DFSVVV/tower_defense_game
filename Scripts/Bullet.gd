extends CharacterBody2D
class_name BaseBullet

var target
var speed
var bulletDamage
var target_enemy: CharacterBody2D


var hit_set: Dictionary = {}


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
	#用 move_and_collide，稳定命中
	#var collision = move_and_collide(velocity * delta)
	#if collision:
		#var body = collision.get_collider()
		#on_hit(body)
#
#func on_hit(body):
	#if body is BaseEnemy:
		#body.take_damage(bulletDamage)
	#queue_free()


func _on_collision_body_entered(body):
	if body is BaseEnemy:
		#防止多次触发（同一只怪）
		var dmg: int = int(round(bulletDamage + bulletDamage * Game.global_damage_bonus))

		# ✅ 暴击判定
		if randf() < Game.global_crit_chance:
			dmg = int(round(dmg * Game.global_crit_mul))
			# 可选：打印或播特效
			# print("CRIT!", dmg)

		body.take_damage(dmg)
		queue_free()



	
