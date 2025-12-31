extends StaticBody2D
class_name BaseTower
@export_category("塔属性")
@export var bullet_scene: PackedScene = preload("res://Bullet/BaseBullet.tscn")# 拖入不同的子弹场景 (如 RedBullet.tscn)
@export var base_damage: int = 20
@export var base_range: int = 320
@export var fire_rate: float = 0.5 # 射击间隔 (秒)，替代原本的 reload 逻辑
@export var bullet_speed: int = 1000#子弹飞行速度
@export var build_cost: int = 50#建造花费
@export var update_range_cost: int = 10
@export var update_damage_cost: int = 10
@export var update_fire_rate_cost: int = 10
@export var description: String = "这是一个发射普通子弹的塔"

@onready var shoot_sfx: AudioStreamPlayer = $ShootSfx

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
func _process(_delta):
	get_node("Upgrade/ProgressBar").global_position = self.position + Vector2(-64,-81)
	if not is_instance_valid(curr):
		curr = null # 确保变量干净
		_update_target() # 重新寻找
	if is_instance_valid(curr) and locate:
		#self.look_at(curr.global_position)
		if timer.is_stopped():
			Shoot(curr)
			timer.start()
	timer.wait_time = fire_rate /(1 + Game.global_speed_bonus)
	update_powers()
func Shoot(target_node:CharacterBody2D):
	var tempBullet = bullet_scene.instantiate()
	tempBullet.set_target(target_node)
	tempBullet.speed = bullet_speed	
	tempBullet.bulletDamage = base_damage  + Game.global_damage_bonus
	get_node("BulletContainer").add_child(tempBullet)
	tempBullet.global_position = $Aim.global_position
	_play_shot_sfx()
	
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
		# 1. 处理其他塔的UI隐藏逻辑 (保持不变)
		var towerPath = get_tree().get_root().get_node("Main/Towers")
		for i in towerPath.get_child_count():
			if towerPath.get_child(i).name != self.name:
				towerPath.get_child(i).get_node("Upgrade/Upgrade").hide()
		
		var upgrade_ui = get_node("Upgrade/Upgrade")
		
		# 2. 切换显示状态
		upgrade_ui.visible = !upgrade_ui.visible
		
		if upgrade_ui.visible:
			# --- 智能定位逻辑开始 ---
			
			# A. 获取必要参数
			var vp_size = get_viewport_rect().size
			# 获取塔在屏幕上的位置 (这是关键，无论摄像机怎么动，这个坐标是相对于屏幕左上角的)
			var tower_screen_pos = get_global_transform_with_canvas().origin
			
			# 获取UI的实际大小 (如果是Godot 3请用 rect_size, Godot 4用 size)
			# 乘以 scale 是为了防止你缩放了UI导致计算不准
			var ui_size = upgrade_ui.size * upgrade_ui.scale 
			
			# B. 定义默认偏移量 (默认向左，向下)
			# x = -790 (向左), y = 81 (向下)
			var offset_x = -790
			var offset_y = 81
			
			# --- C. 左/右边界判断 ---
			# 逻辑：既然默认是向左弹 (-790)，我们只要检查“塔是否太靠左了”
			# 如果塔的屏幕X坐标 小于 800 (也就是左侧空间不够放下UI了)
			if tower_screen_pos.x < 800:
				# 改为向右弹出 (根据你的塔宽适当调整，比如向右偏移100)
				offset_x = 100 
			# (如果你的默认是向右弹，这里就需要判断 if tower_screen_pos.x > vp_size.x - 800)
			if tower_screen_pos.x > 2800:
				offset_x = -1500
			# --- D. 上/下边界判断 ---
			# 逻辑：计算一下“如果按默认向下放，UI底部会不会超出屏幕下沿？”
			# 预测的底部位置 = 塔的屏幕Y + 偏移Y + UI的高度
			var expected_bottom = tower_screen_pos.y + offset_y + ui_size.y
			
			# 如果预测底部 超过了 屏幕高度
			if expected_bottom > vp_size.y:
				# 改为向上弹出
				# 新的Y偏移 = 负的UI高度 - 一点间距(比如20像素)
				offset_y = -ui_size.y - 20
			
			# --- E. 应用最终坐标 ---
			# 注意：这里赋值给 global_position
			upgrade_ui.global_position = self.global_position + Vector2(offset_x, offset_y)
func _on_range_pressed():
	if Game.Gold >= update_range_cost:
		if base_range < 600 :
			base_range += 30
			Game.Gold -= update_range_cost
			addValue(update_range_cost)
			if base_range >= 600:
				$Upgrade/Upgrade/HBoxContainer/Range.disabled = true
				$Upgrade/Upgrade/HBoxContainer/Range/Label2.text = "MAX"
		else:
			return
func _on_attack_speed_pressed():
	if Game.Gold >= update_fire_rate_cost:
		if fire_rate > 0.85:
			fire_rate -= 0.03
			Game.Gold -= update_fire_rate_cost
			addValue(update_fire_rate_cost)
			if fire_rate <= 0.85:
				$Upgrade/Upgrade/HBoxContainer/AttackSpeed.disabled = true
				$Upgrade/Upgrade/HBoxContainer/AttackSpeed/Label2.text = "MAX"
		else:
			return
func _on_power_pressed():
	if Game.Gold >= update_damage_cost:
		if base_damage < 30:
			base_damage += 1
			Game.Gold -= update_damage_cost
			addValue(update_damage_cost)
			if base_damage >= 30:
				$Upgrade/Upgrade/HBoxContainer/Power.disabled = true
				$Upgrade/Upgrade/HBoxContainer/Power/Label2.text = "MAX"
		else:
			return
		
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
	get_node("Upgrade/Upgrade/HBoxContainer/AttackSpeed/Label").text = "%.2f" % (fire_rate / (1 + Game.global_speed_bonus))
	get_node("Upgrade/Upgrade/HBoxContainer/Power/Label").text = str(base_damage + Game.global_damage_bonus)
	
	get_node("Tower/CollisionShape2D").shape.radius = base_range
func addValue(num:int):
	self.value += num

func _play_shot_sfx():
	if is_instance_valid(shoot_sfx):
		shoot_sfx.play()
