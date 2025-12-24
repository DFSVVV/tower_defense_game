extends StaticBody2D

@export_category("塔属性")
@export var bullet_scene: PackedScene = preload("res://Bullet/BaseBullet.tscn")# 拖入不同的子弹场景 (如 RedBullet.tscn)
@export var base_damage: int = 5
@export var base_range: int = 400
@export var fire_rate: float = 1.0 # 射击间隔 (秒)，替代原本的 reload 逻辑
@export var bullet_speed: int = 1000#子弹飞行速度
@export var build_cost: int = 10#建造花费
@export var update_range_cost: int = 10
@export var update_damage_cost: int = 10
@export var update_fire_rate_cost: int = 10

var pathName
var currTargets = []
var curr
var tower_area 
var value
var locate = false
@onready var timer = get_node("Upgrade/ProgressBar/Timer")
var startShooting = false

func _ready():
	get_node("Upgrade/Upgrade").hide()
	tower_area = get_node("Tower")
	value = build_cost
func _process(delta):
	get_node("Upgrade/ProgressBar").global_position = self.position + Vector2(-64,-81)
	if not is_instance_valid(curr):
		curr = null # 确保变量干净
		_update_target() # 重新寻找
	if is_instance_valid(curr) and locate:
		self.look_at(curr.global_position)
		if timer.is_stopped():
			Shoot(curr)
			timer.start()
	update_powers()
func Shoot(target_node:CharacterBody2D):
	var tempBullet = bullet_scene.instantiate()
	tempBullet.set_target(target_node)
	tempBullet.speed = bullet_speed	
	tempBullet.bulletDamage = base_damage  + Game.global_damage_bonus
	get_node("BulletContainer").add_child(tempBullet)
	tempBullet.global_position = $Aim.global_position
	
func _update_target():
	# 获取当前圈内所有敌人
	var all_enemies = tower_area.get_overlapping_bodies()
	var best_target = null
	var max_progress = -1.0 # 初始进度设为负数
	
	for body in all_enemies:
		if body is BaseEnemy:
			# 假设结构是 PathFollow2D -> CharacterBody2D
			# body.get_parent() 就是 PathFollow2D
			var path_node = body.get_parent()
			
			# 必须确保它真的是个 PathFollow2D 才有 progress 属性
			if path_node is PathFollow2D:
				var current_progress = path_node.get_progress()
				
				# 谁跑得远，谁就是最佳目标
				if current_progress > max_progress:
					max_progress = current_progress
					best_target = body
	
	# 更新当前目标
	curr = best_target
	if curr:
		pathName = curr.get_parent().name
func _on_tower_body_entered(body):
	if body is BaseEnemy:
		_update_target()

func _on_tower_body_exited(body):
	if body == curr:
		curr = null # 先清空
		_update_target() # 赶紧看看范围里还剩谁，挑个最好的继续打


func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_mask == 1:
		var towerPath = get_tree().get_root().get_node("Main/Towers")
		for i in towerPath.get_child_count():
			if towerPath.get_child(i).name != self.name:
				towerPath.get_child(i).get_node("Upgrade/Upgrade").hide()
		get_node("Upgrade/Upgrade").visible = !get_node("Upgrade/Upgrade").visible
		get_node("Upgrade/Upgrade").global_position = self.position + Vector2(-572,81)
		

func _on_range_pressed():
	if Game.Gold >= update_range_cost:
		base_range += 30
		Game.Gold -= update_range_cost
		addValue(update_range_cost)
func _on_attack_speed_pressed():
	if Game.Gold >= update_fire_rate_cost:
		if fire_rate > 0.15:
			fire_rate -= 0.1
			timer.wait_time = fire_rate
			Game.Gold -= update_fire_rate_cost
			addValue(update_fire_rate_cost)
		else:
			return
func _on_power_pressed():
	if Game.Gold >= update_damage_cost:
		base_damage += 1
		Game.Gold -= update_damage_cost
		addValue(update_damage_cost)
		
func _on_delete_pressed() :
	Game.Gold += int(value * 0.7)
	self.queue_free()
func _on_timer_timeout():
	if curr != null :
		Shoot(curr)
	else :
		timer.stop()
		var bar = get_node("Upgrade/ProgressBar")
		bar.value = bar.max_value


func _on_range_mouse_entered():
	get_node("Tower/CollisionShape2D").show()


func _on_range_mouse_exited():
	get_node("Tower/CollisionShape2D").hide()


func update_powers():
	get_node("Upgrade/Upgrade/HBoxContainer/Range/Label").text = str(base_range)
	get_node("Upgrade/Upgrade/HBoxContainer/AttackSpeed/Label").text = str(fire_rate)
	get_node("Upgrade/Upgrade/HBoxContainer/Power/Label").text = str(base_damage + Game.global_damage_bonus)
	
	get_node("Tower/CollisionShape2D").shape.radius = base_range
func addValue(num:int):
	self.value += num
