extends Panel
class_name BaseTowerPanel
@export_category("Tower Settings")
@export var tower: PackedScene = preload("res://Towers/BaseTower.tscn") # 在这里拖入你的 RedBullet.tscn, BlueTower.tscn 等
@export var tower_cost: int = 50     # 在这里设置这个塔的价格

@onready var place_player: AudioStreamPlayer = get_tree().get_root().get_node("Main/AudioStreamPlayer2")

var currTile
func _ready():
	# 设置鼠标光标形状为手型，提示可交互
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_generate_tower_info()

func _generate_tower_info():
	if tower == null:
		return
	
	# 实例化一个临时的塔来读取数据
	var temp_tower = tower.instantiate()
	
	# 检查这个塔是否有我们需要的属性 (防止报错)
	var info_text = ""
	
	# 只有当变量存在时才读取
	if "description" in temp_tower:
		info_text += "%s\n" % temp_tower.description
		info_text += "----------------\n"
	
	if "base_damage" in temp_tower:
		info_text += "攻击力: %d\n" % temp_tower.base_damage
		
	if "fire_rate" in temp_tower:
		info_text += "攻速: %.1f 秒/发\n" % temp_tower.fire_rate
		
	if "base_range" in temp_tower:
		info_text += "射程: %d\n" % temp_tower.base_range
		
	if "bullet_speed" in temp_tower:
		info_text += "弹速: %d\n" % temp_tower.bullet_speed
	
	# 也可以加上造价提示
	info_text += "\n建造花费: %d 金币" % tower_cost
	# 也可以加上造价提示
	info_text += "\n升级范围花费: %d 金币" % temp_tower.update_range_cost
	# 也可以加上造价提示
	info_text += "\n升级射速花费: %d 金币" % temp_tower.update_fire_rate_cost
	# 也可以加上造价提示
	info_text += "\n升级伤害花费: %d 金币" % temp_tower.update_damage_cost
	# 将生成的文本赋值给 Panel 自带的 tooltip_text 属性
	tooltip_text = info_text
	
	# 读取完数据后，销毁临时塔，释放内存
	temp_tower.queue_free()
func _on_gui_input(event):
	if Game.Gold >= tower_cost:
		var tempTower = tower.instantiate()
		if event is InputEventMouseButton and event.button_mask == 1:
			
			add_child(tempTower)
			tempTower.global_position = event.global_position
			#tempTower.process_mode = Node.PROCESS_MODE_DISABLED
			
			tempTower.scale = Vector2(0.32,0.32)
			tempTower.get_node("Upgrade/Upgrade").hide()
			tempTower.get_node("Upgrade/ProgressBar").hide()
		
		elif event is InputEventMouseMotion and event.button_mask == 1:
			if get_child_count() > 1:
				
				get_child(1).global_position = event.global_position
				var mapPath = get_tree().get_root().get_node("Main/TileMap")
				var tile = mapPath.local_to_map(get_global_mouse_position())
				currTile = mapPath.get_cell_atlas_coords(tile)
				var targets = get_child(1).get_node("TowerDetector").get_overlapping_bodies()
				if (currTile == Vector2i(5,5)):
					if (targets.size() > 1):
						get_child(1).get_node("Area").modulate = Color(255,255,255)
					else:
						get_child(1).get_node("Area").modulate = Color(0,255,0)
				else:
					
					get_child(1).get_node("Area").modulate = Color(255,255,255)
		elif event is InputEventMouseButton and event.button_mask == 0:
			if event.global_position.x >= 2683 and event.global_position.y <= 339.0:
				if get_child_count() > 1:
					get_child(1).queue_free()
			else:
				if get_child_count() > 1:
					get_child(1).queue_free()
				if currTile == Vector2i(5,5):
					var targets = get_child(1).get_node("TowerDetector").get_overlapping_bodies()
					var path = get_tree().get_root().get_node("Main/Towers")
					if (targets.size() < 2):
						path.add_child(tempTower)
						tempTower.global_position = event.global_position
						tempTower.get_node("Area").hide()
						Game.Gold -= tower_cost
						
						place_player.stop()
						place_player.play()
						
						tempTower.locate = true
		else:
			if get_child_count() > 1:
				get_child(1).queue_free()
				
