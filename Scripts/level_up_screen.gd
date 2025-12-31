extends CanvasLayer


var all_upgrades: Array[UpgradeItem] = [] 
const UPGRADES_PATH = "res://Resources/"
@onready var card_container = $HBoxContainer
@export var card_scene: PackedScene = preload("res://UI/upgrade_card_button.tscn")
func _ready():
	#加载卡牌
	load_upgrades_from_folder()
	# 初始隐藏
	visible = false
	# 连接 Game 单例的信号
	Game.level_up_ready.connect(_on_level_up_ready)
	
func get_upgrade_level(id: String) -> int:
	# 你可以把 upgrade_levels 放在 Game.gd
	return Game.upgrade_levels.get(id, 0)

	
func load_upgrades_from_folder():
	var dir = DirAccess.open(UPGRADES_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				# --- 修改开始 ---
				# 1. 在导出后，Godot可能会添加 .remap 后缀，先尝试去掉它
				var raw_name = file_name
				if file_name.ends_with(".remap"):
					raw_name = file_name.trim_suffix(".remap")
				
				# 2. 检查是否是 .tres 资源
				if raw_name.ends_with(".tres"):
					# 注意：load 的时候不需要带 .remap，Godot 引擎会自动处理
					var full_path = UPGRADES_PATH + "/" + raw_name 
					var resource = load(full_path)
					if resource is UpgradeItem:
						all_upgrades.append(resource)
				# --- 修改结束 ---
				
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("错误：无法打开文件夹")
func _on_level_up_ready():
	# 1. 暂停游戏
	get_tree().paused = true
	# 2. 显示 UI
	visible = true
	Game.upgrade = true
	# 3. 生成 3 个随机选项
	generate_options()

func generate_options():
	# 清空旧的选项
	for child in card_container.get_children():
		child.queue_free()
	var available = all_upgrades.duplicate()
	available.shuffle() # 洗牌
	var count = min(3, available.size())
	for i in range(count):
		create_card(available[i])

func create_card(item: UpgradeItem):
	var card = card_scene.instantiate()
	card_container.add_child(card)
	card.set_info(item.title, item.description, item.icon)
	card.pressed.connect(_on_card_selected.bind(item))


func _on_card_selected(item: UpgradeItem):
	print("选择了升级: ", item.title)

	# 记录等级（你需要在 Game.gd 里有 upgrade_levels: Dictionary）
	Game.upgrade_levels[item.id] = Game.upgrade_levels.get(item.id, 0) + 1

	apply_upgrade_effect(item)

	visible = false
	Game.upgrade = false
	get_tree().paused = false

#func _on_card_selected(item: UpgradeItem):
	#print("选择了升级: ", item.title)	
	#apply_upgrade_effect(item)
	#visible = false
	#Game.upgrade = false
	#get_tree().paused = false
	#Game.gain_research(0)

func apply_upgrade_effect(item: UpgradeItem):
	var _lvl = Game.upgrade_levels.get(item.id, 1)
	match item.id:
		"damage":
			Game.global_damage_bonus += item.value
		"speed":
			Game.global_speed_bonus += item.value
		"gold":
			Game.gain_gold(int(item.value))
		"pierce":
			Game.global_pierce += int(item.value)  # value=1
		"crit":
			Game.global_crit_chance = clamp(Game.global_crit_chance + float(item.value), 0.0, 1.0)
		"health":
			Game.Health += item.value
		"crit_mul":
			Game.global_crit_mul += float(item.value)
