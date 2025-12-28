extends BaseBullet
class_name SlowBullet

# 减速子弹专属属性（父类没有，新增）
@export var slow_percent: float = 0.3  # 减速百分比（0.3=30%）
@export var slow_duration: float = 2.0  # 减速持续时间（秒）

# 无需重复定义 target_enemy、speed、bulletDamage（父类已声明）
# 无需重复定义 set_target 方法（父类已实现）
# 无需重复定义 _physics_process 方法（父类已实现子弹追踪移动）
# 无需重复定义 _on_collision_body_entered 方法（后续重写补充减速逻辑即可）

# 重写碰撞伤害方法：在父类伤害逻辑基础上，新增减速效果
func _on_collision_body_entered(body):
	# 先调用父类的碰撞逻辑（确保伤害生效、子弹销毁）
	# 兼容父类逻辑，避免重写后丢失伤害功能
	super._on_collision_body_entered(body)
	
	# 额外补充减速效果：仅对 BaseEnemy 生效
	if body is BaseEnemy:
		apply_slow_effect(body)

# 减速子弹专属：给敌人施加减速效果
func apply_slow_effect(enemy: BaseEnemy):
	# 1. 保存敌人原始速度（避免重复减速覆盖，兼容多次命中）
	if not enemy.has_meta("original_speed"):
		enemy.set_meta("original_speed", enemy.speed)
	
	# 2. 停止敌人身上已有的减速计时器（避免多个减速效果叠加异常）
	if enemy.has_node("slow_timer"):
		enemy.get_node("slow_timer").queue_free()
	
	# 3. 计算并应用减速后的速度
	var original_speed = enemy.get_meta("original_speed")
	var slowed_speed = original_speed * (1 - slow_percent)
	enemy.speed = slowed_speed
	
	# 4. 创建减速计时器，到期后恢复原始速度
	var slow_timer = Timer.new()
	slow_timer.name = "slow_timer"  # 命名方便查找和销毁
	slow_timer.wait_time = slow_duration
	slow_timer.one_shot = true  # 单次触发（减速结束后不再重复）
	
	# 计时器超时后恢复速度
	slow_timer.connect("timeout", func():
		if is_instance_valid(enemy):  # 防止敌人已销毁报错
			enemy.speed = original_speed
	)
	
	# 5. 将计时器添加到敌人节点，启动计时器
	enemy.add_child(slow_timer)
	slow_timer.start()
