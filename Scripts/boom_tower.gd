extends BaseTower  # 继承基础塔类
class_name BoomTower  # 定义类名，方便编辑器识别

# 范围塔专属配置（可视化分组，便于编辑器调整）
@export_category("范围伤害属性")
@export var splash_damage_bonus: int = 4  # 范围额外伤害（区别于单体基础伤害）
@export var explosion_radius: int = 500  # 子弹爆炸范围（传递给子弹）
@export var is_aoe_damage: bool = true  # 固定为范围伤害类型
@onready var fire_point: Node2D = $Aim  # 复用BaseTower的Aim节点作为发射点，避免额外创建节点

# 范围塔升级配置（优化硬编码，便于平衡调整）
@export_category("升级配置")
@export var explosion_radius_upgrade_cost: int = 30  # 爆炸范围升级成本
@export var explosion_radius_increment: int = 50    # 每次升级半径增量

# 重写_ready方法，初始化范围塔专属配置
func _ready():
	# 调用父类_ready，确保基础逻辑（升级、目标锁定、计时器等）正常生效
	super._ready()
	
	# 预加载配套范围子弹预制体（替换为你的实际资源路径）
	bullet_scene = preload("res://Bullet/boom_bullet.tscn")
	
	# 覆盖基础塔默认属性，适配范围爆炸塔定位（侧重清场，性价比更高）
	base_damage = 6  # 基础伤害略高于减速塔
	base_range = 450  # 射程适中，平衡输出与站位
	fire_rate = 1.2   # 射击间隔略短，保证清场频率
	bullet_speed = 900  # 子弹速度均衡，兼顾命中与射程
	build_cost = 20  # 建造成本高于减速塔，符合范围伤害价值
	update_range_cost = 20
	update_damage_cost = 25  # 伤害升级优先级最高（核心属性）
	update_fire_rate_cost = 15  # 攻速升级优先级稍低

# 重写Shoot方法，适配BaseEnemy逻辑，安全发射范围子弹
func Shoot(target_node: CharacterBody2D):
	# 安全校验：目标有效且为BaseEnemy类型，避免空对象报错
	if not is_instance_valid(target_node) or not target_node is BaseEnemy:
		return
	
	# 实例化范围子弹
	var tempBullet = bullet_scene.instantiate()
	tempBullet.set_target(target_node)
	tempBullet.speed = bullet_speed
	
	# 计算最终范围伤害：基础伤害 + 全局伤害加成 + 范围专属加成
	var final_splash_damage = base_damage + Game.global_damage_bonus + splash_damage_bonus
	tempBullet.bulletDamage = final_splash_damage
	
	# 将塔的爆炸半径传递给子弹（由塔统一控制，便于全局调整）
	tempBullet.explosion_radius = self.explosion_radius
	
	# 安全挂载子弹（兼容BulletContainer节点缺失的情况）
	var bullet_container = get_node_or_null("BulletContainer")
	if is_instance_valid(bullet_container):
		bullet_container.add_child(tempBullet)
	else:
		add_child(tempBullet)
	
	# 安全设置子弹发射位置（优先用Aim节点，失败则用塔自身位置，避免null报错）
	if is_instance_valid(fire_point):
		tempBullet.global_position = fire_point.global_position
	else:
		tempBullet.global_position = global_position

# 专属升级：扩大爆炸范围（丰富升级维度）
func _on_explosion_radius_pressed():
	# 校验金币是否充足，执行升级逻辑
	if Game.Gold >= explosion_radius_upgrade_cost:
		explosion_radius += explosion_radius_increment
		Game.Gold -= explosion_radius_upgrade_cost
		addValue(explosion_radius_upgrade_cost)
		update_powers()  # 升级后更新UI显示

# 重写伤害升级方法，适配范围塔核心需求（同步提升基础伤害与范围加成）
func _on_power_pressed():
	if Game.Gold >= update_damage_cost:
		base_damage += 2  # 基础伤害增量，保证单体输出提升
		splash_damage_bonus += 1  # 同步提升范围额外伤害，强化清场能力
		Game.Gold -= update_damage_cost
		addValue(update_damage_cost)

# 重写攻速升级方法，适配范围塔输出密度需求
func _on_attack_speed_pressed():
	if Game.Gold >= update_fire_rate_cost:
		# 更低的最小射击间隔，保证范围塔清场效率
		if fire_rate > 0.2:
			fire_rate -= 0.1  # 每次升级小幅降低间隔，避免攻速溢出
			timer.wait_time = fire_rate  # 更新计时器，生效新攻速
			Game.Gold -= update_fire_rate_cost
			addValue(update_fire_rate_cost)
		else:
			return

# 重写属性更新方法，显示范围塔专属属性（兼容UI标签缺失）
func update_powers():
	# 调用父类更新逻辑，保证基础属性（射程、攻速等）正常显示
	super.update_powers()
	
	# 计算总范围伤害（含所有加成），用于UI显示
	var total_splash_damage = base_damage + splash_damage_bonus + Game.global_damage_bonus 
