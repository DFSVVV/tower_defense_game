extends CharacterBody2D
class_name BaseEnemy

@export_group("敌人属性")
@export var health: int = 60
@export var speed: float = 200.0
@export var gold_reward: int = 10
@export var research_point : int = 1

# --- 来自 002 的变量 (结构更好) ---
var is_dead := false
@onready var explosion_particles: CPUParticles2D = $ExplosionParticles
# 提前获取父节点，比每次都调用 get_parent() 性能更好
@onready var follow: PathFollow2D = get_parent() as PathFollow2D

# --- 来自 HEAD 的音效变量 (保留你的音效逻辑) ---
# 注意：确保你的场景树里 Main 节点下确实有这两个 AudioStreamPlayer
@onready var place_player1: AudioStreamPlayer = get_tree().get_root().get_node("Main/AudioStreamPlayer3") # 终点音效
@onready var place_player2: AudioStreamPlayer = get_tree().get_root().get_node("Main/AudioStreamPlayer4") # 死亡音效

func _ready():
	add_to_group("enemies")

func _physics_process(delta):
	# 如果死了或者没有父节点，就停止移动逻辑
	if is_dead:
		return
	if follow == null:
		return
		
	follow.progress += speed * delta

	# 到达终点判定
	if follow.progress_ratio >= 1.0:
		Game.Health -= 1
		
		# [保留 HEAD 逻辑] 播放到达终点音效
		if place_player1:
			place_player1.stop()
			place_player1.play()
		
		die(false) # false 代表不是被塔击杀，而是逃跑了（不给金币不爆特效）

func take_damage(dmg: int) -> void:
	if is_dead:
		return

	health -= dmg

	if health <= 0:
		# [保留 HEAD 逻辑] 播放死亡音效
		if place_player2:
			place_player2.stop()
			place_player2.play()

		# [保留 002 逻辑] 统一处理奖励
		Game.gain_gold(gold_reward)
		Game.gain_research(research_point)
		
		die(true) # true 代表是被玩家击杀的

# 统一的死亡处理函数 (来自 002 优化版)
# killed 参数决定是否播放爆炸特效
func die(killed: bool) -> void:
	if is_dead:
		return
	is_dead = true

	Game.EnemyNum -= 1

	# 只有被击杀时才播放爆炸特效，走到终点不需要
	if killed:
		spawn_death_particles()

	# 敌人挂在 Follow 下，删 Follow 就能一起删掉
	if follow != null:
		follow.queue_free()
	else:
		queue_free()

func restore_speed():
	# 恢复原始速度
	if has_meta("original_speed"):
		speed = get_meta("original_speed")
		# 移除临时计时器（避免内存泄漏）
		for child in get_children():
			if child is Timer and child.name == "slow_timer":
				child.queue_free()

func spawn_death_particles():
	if not explosion_particles:
		return
		
	explosion_particles.emitting = false
	remove_child(explosion_particles)
	get_tree().current_scene.add_child(explosion_particles)
	explosion_particles.global_position = global_position
	explosion_particles.emitting = true
	var t := explosion_particles.lifetime + explosion_particles.preprocess
	await get_tree().create_timer(t).timeout
	explosion_particles.queue_free()
