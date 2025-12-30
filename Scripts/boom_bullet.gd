extends BaseBullet
class_name BoomBullet

# 范围伤害子弹专属属性（父类没有，新增）
@export var explosion_radius: int = 500 # 爆炸范围半径（像素）
# 优化硬编码：改为可导出属性，便于编辑器调整
@export var min_explode_distance: int = 20  # 近距离强制爆炸距离阈值
@export var enemy_collision_mask: int = 1    # 敌人碰撞掩码

# 重写碰撞触发方法：移除父类调用（避免父类提前销毁子弹导致爆炸失效），直接触发爆炸
func _on_collision_body_entered(body):
	# 范围爆炸触发逻辑：碰到敌人必爆炸（与父类扣血逻辑的目标对象一致）
	if body is BaseEnemy :
		trigger_explosion()

# 重写子弹移动逻辑：补充距离过近强制爆炸，同时保留父类追踪逻辑
func _physics_process(delta):
	# 先调用父类的子弹追踪移动逻辑（确保子弹正常飞向目标）
	super._physics_process(delta)
	
	# 安全校验：目标有效才进行距离判断
	if is_instance_valid(target_enemy):
		var distance_to_target = global_position.distance_to(target_enemy.global_position)
		# 使用可导出属性替代硬编码，距离小于阈值时强制触发爆炸（防止高速穿透）
		if distance_to_target < min_explode_distance:
			trigger_explosion()

# 范围子弹专属：核心爆炸伤害逻辑（补充血量清零死亡处理）
func trigger_explosion():
	# 1. 安全校验：获取有效伤害值（与父类bulletDamage属性对应，避免空值报错）
	var safe_bullet_damage = bulletDamage if bulletDamage != null else 0
	var final_splash_damage = max(safe_bullet_damage, 0)

	# 2. 强制创建圆形爆炸检测区域（确保范围形状有效）
	var explosion_shape = CircleShape2D.new()
	explosion_shape.radius = explosion_radius  # 强制赋值，避免属性未初始化
	print("爆炸范围：", explosion_radius, " 爆炸中心：", global_position) # 调试用，查看爆炸参数

	# 3. 配置物理空间查询参数（修复核心检测漏洞）
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = explosion_shape
	query.transform = Transform2D(0, global_position)  # 明确爆炸中心为子弹当前位置
	query.collision_mask = enemy_collision_mask  # 使用可导出属性，与敌人CollisionLayer对应
	query.collide_with_bodies = true  # 强制开启检测刚体（敌人是CharacterBody2D，属于刚体）
	query.collide_with_areas = false  # 关闭区域检测，避免干扰

	# 4. 执行范围检测并打印结果（便于调试是否检测到敌人）
	var enemies_in_explosion = space_state.intersect_shape(query)
	print("检测到范围内物体数量：", enemies_in_explosion.size()) # 调试用

	# 5. 遍历爆炸范围内的所有敌人，执行扣血+死亡逻辑（与父类风格一致）
	for result in enemies_in_explosion:
		var enemy_body = result.get("collider")
		# 严格校验：仅对有效、存活的BaseEnemy生效
		if is_instance_valid(enemy_body) and enemy_body is BaseEnemy and enemy_body.health > 0:
			# 与父类一致的扣血逻辑（直接修改health属性）
			enemy_body.health -= final_splash_damage
			print("对", enemy_body.name, "造成范围伤害：", final_splash_damage, " 剩余血量：", enemy_body.health)
			# 关键补充：血量≤0时触发敌人死亡（核心修复点）
			# 这里不用管，敌人会自己死亡
			# if enemy_body.health <= 0:
				# enemy_body.queue_free()
	# 6. 爆炸后强制销毁子弹（避免子弹残留，确保逻辑闭环）
	self.queue_free()
