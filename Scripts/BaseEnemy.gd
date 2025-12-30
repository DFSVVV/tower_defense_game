extends CharacterBody2D
class_name BaseEnemy

@export_group("敌人属性") # 加上分组更好看
@export var health: int = 10
@export var speed: int = 1000
@export var gold_reward: int = 10
@export var research_point : int = 1

var is_dead := false
@onready var explosion_particles: CPUParticles2D = $ExplosionParticles

@onready var follow: PathFollow2D = get_parent() as PathFollow2D
func _ready():
	add_to_group("enemies")


func _physics_process(delta):
	get_parent().set_progress(get_parent().get_progress() + speed*delta)
	
	if get_parent().get_progress_ratio() == 1:
		Game.Health-=1
		death()
		
	follow.progress += speed * delta

	if follow.progress_ratio >= 1.0:
		Game.Health -= 1
		die(false) # 到终点不算击杀
	#get_parent().set_progress(get_parent().get_progress() + speed*delta)
	
	#if get_parent().get_progress_ratio() == 1:
		#Game.Health-=1
		#death()
		#
	#if health <= 0:
		#death()
		#Game.gain_gold(gold_reward)
		#Game.gain_research(research_point)
	
func take_damage(dmg: int) -> void:
	if is_dead:
		return

	health -= dmg

	if health <= 0:
		death()
		Game.gain_gold(gold_reward)
		Game.gain_research(research_point)
		die(true)
		
		
func die(killed: bool) -> void:
	if is_dead:
		return
	is_dead = true

	Game.EnemyNum -= 1

	# ✅ 如果你想“到终点不爆特效/不加金币”，用 killed 区分
	if killed:
		spawn_death_particles()

	# 敌人挂在 Follow 下，删 Follow 就能一起删掉
	if follow != null:
		follow.queue_free()
	else:
		queue_free()
#func death():
	#spawn_death_particles()
	#Game.EnemyNum -=1
	#if follow != null:
		#follow.queue_free()
	#else:
		#get_parent().get_parent().queue_free()
func restore_speed():
	# 恢复原始速度
	if has_meta("original_speed"):
		speed = get_meta("original_speed")
		# 移除临时计时器（避免内存泄漏）
		for child in get_children():
			if child is Timer and child.name == "slow_timer":
				child.queue_free()
func spawn_death_particles():
	explosion_particles.emitting = false
	remove_child(explosion_particles)
	get_tree().current_scene.add_child(explosion_particles)
	explosion_particles.global_position = global_position
	explosion_particles.emitting = true
	var t := explosion_particles.lifetime + explosion_particles.preprocess
	await get_tree().create_timer(t).timeout
	explosion_particles.queue_free()
