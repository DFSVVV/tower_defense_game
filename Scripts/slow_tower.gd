extends BaseTower  # 继承你提供的基础塔类
class_name SlowTower  # 定义类名，方便编辑器识别

# 减速塔专属配置
@export_category("减速属性")
@export var slow_percent: float = 0.3  # 减速百分比（0.3 = 降低30%移速）
@export var slow_duration: float = 2.0  # 减速持续时间（秒）
@export var slow_radius: int = 200  # 减速生效范围（如果是范围减速）
@export var is_aoe_slow: bool = false  # 是否为范围减速（true=范围，false=单体）
@onready var attack_area: Area2D = $AttackDetector/Area2D  # 攻击范围检测区域
@onready var fire_point: Node2D = $FirePoint  # 子弹发射点（在编辑器中创建并摆放位置）

# 重写_ready方法，初始化减速塔专属配置
func _ready():
	# 调用父类的_ready，确保基础逻辑生效
	super._ready()
	
	bullet_scene = preload("res://Bullet/slow_bullet.tscn")
	# 覆盖基础塔的默认属性，适配减速塔定位
	base_damage = 5  # 减速塔伤害较低
	base_range = 500  # 减速塔射程更远
	fire_rate = 1.5   # 减速效果触发间隔
	bullet_speed = 800  # 子弹速度稍慢，更容易命中
	build_cost = 15  # 建造成本略高于基础塔
	update_range_cost = 15
	update_damage_cost = 10  # 减速塔升级伤害性价比低
	update_fire_rate_cost = 20  # 升级攻速优先级更高

# 重写Shoot方法，替换为减速逻辑（修复重复扣血，优化范围检测）
func Shoot(target_node: CharacterBody2D):
	# 安全检查：目标有效
	if not is_instance_valid(target_node) or not target_node is BaseEnemy:
		return
	
	var tempBullet = bullet_scene.instantiate()
	tempBullet.set_target(target_node)
	tempBullet.speed = bullet_speed	
	tempBullet.bulletDamage = base_damage  + Game.global_damage_bonus
	get_node("BulletContainer").add_child(tempBullet)
	if is_instance_valid(fire_point):
		tempBullet.global_position = fire_point.global_position
	else:# 降级使用塔本身的位置，避免崩溃
		tempBullet.global_position = global_position

	# 1. 单体减速逻辑（移除重复扣血）
	if not is_aoe_slow:
		apply_slow_effect(target_node)
	
	# 2. 范围减速逻辑（使用direct_space_state，无需临时Area2D）
	else:
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsShapeQueryParameters2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = slow_radius
		query.shape = circle_shape
		query.transform = Transform2D(0, target_node.global_position)
		query.collide_with_bodies = true
		query.collide_with_areas = false
		
		var enemies_in_range = space_state.intersect_shape(query)
		for result in enemies_in_range:
			var enemy = result.get("collider")
			if enemy is BaseEnemy and is_instance_valid(enemy):
				apply_slow_effect(enemy)
	
	_play_shot_sfx()

# 核心方法：给敌人应用减速效果（优化计时器命名与重复创建）
func apply_slow_effect(enemy: BaseEnemy):
	# 保存敌人原始速度（避免重复减速覆盖）
	if not enemy.has_meta("original_speed"):
		enemy.set_meta("original_speed", enemy.speed)
	
	# 先清理已存在的减速计时器，避免重复创建
	for child in enemy.get_children():
		if child is Timer and child.name == "slow_timer":
			child.queue_free()
	
	# 计算减速后的速度
	var original_speed = enemy.get_meta("original_speed")
	var slowed_speed = original_speed * (1 - slow_percent)
	
	# 应用减速
	enemy.speed = slowed_speed
	
	# 启动计时器，到期后恢复速度（设置固定名称）
	var slow_timer = Timer.new()
	slow_timer.name = "slow_timer"
	slow_timer.wait_time = slow_duration
	slow_timer.one_shot = true
	slow_timer.connect("timeout", func():
		enemy.restore_speed()
	)
	enemy.add_child(slow_timer)
	slow_timer.start()

# 重写升级方法，适配减速塔的升级逻辑
func _on_attack_speed_pressed():
	if Game.Gold >= update_fire_rate_cost:
		if fire_rate > 0.3:  # 减速塔最小间隔稍高，避免减速效果无缝覆盖
			fire_rate -= 0.15  # 每次升级减少更多间隔，提升减速频率
			timer.wait_time = fire_rate
			Game.Gold -= update_fire_rate_cost
			addValue(update_fire_rate_cost)
		else:
			return

# 重写属性更新方法，显示减速相关信息（优化标签绑定）
func update_powers():
	# 调用父类的更新逻辑
	super.update_powers()
