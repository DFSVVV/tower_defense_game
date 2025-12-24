extends Panel
@export_category("Tower Settings")
@export var tower: PackedScene = preload("res://Towers/BaseTower.tscn") # 在这里拖入你的 RedBullet.tscn, BlueTower.tscn 等
@export var tower_cost: int = 10     # 在这里设置这个塔的价格

var currTile

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
				if (currTile == Vector2i(19,6)):
					if (targets.size() > 1):
						get_child(1).get_node("Area").modulate = Color(255,255,255)
					else:
						get_child(1).get_node("Area").modulate = Color(0,255,0)
				else:
					
					get_child(1).get_node("Area").modulate = Color(255,255,255)
		elif event is InputEventMouseButton and event.button_mask == 0:
			if event.global_position.x >= 2944:
				if get_child_count() > 1:
					get_child(1).queue_free()
			else:
				if get_child_count() > 1:
					get_child(1).queue_free()
				if currTile == Vector2i(19,6):
					var targets = get_child(1).get_node("TowerDetector").get_overlapping_bodies()
					var path = get_tree().get_root().get_node("Main/Towers")
					if (targets.size() < 2):
						path.add_child(tempTower)
						tempTower.global_position = event.global_position
						tempTower.get_node("Area").hide()
						Game.Gold -= tower_cost
						tempTower.locate = true
		else:
			if get_child_count() > 1:
				get_child(1).queue_free()
