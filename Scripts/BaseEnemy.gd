extends CharacterBody2D
class_name BaseEnemy

@export_group("敌人属性") # 加上分组更好看
@export var health: int = 10
@export var speed: int = 1000
@export var gold_reward: int = 10
@export var research_point : int = 1
@onready var place_player1: AudioStreamPlayer = get_tree().get_root().get_node("Main/AudioStreamPlayer3")
@onready var place_player2: AudioStreamPlayer = get_tree().get_root().get_node("Main/AudioStreamPlayer4")
func _physics_process(delta):
	get_parent().set_progress(get_parent().get_progress() + speed*delta)
	
	if get_parent().get_progress_ratio() == 1:
		Game.Health-=1
		
		place_player1.stop()
		place_player1.play()
		
		death()
		
	if health <= 0:
		place_player2.stop()
		place_player2.play()
		death()
		Game.gain_gold(gold_reward)
		Game.gain_research(research_point)
	
func death():
	Game.EnemyNum -=1
	print(Game.EnemyNum)
	get_parent().get_parent().queue_free()
func restore_speed():
	# 恢复原始速度
	if has_meta("original_speed"):
		speed = get_meta("original_speed")
		# 移除临时计时器（避免内存泄漏）
		for child in get_children():
			if child is Timer and child.name == "slow_timer":
				child.queue_free()
