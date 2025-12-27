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
func load_upgrades_from_folder():
	# 尝试打开文件夹
	var dir = DirAccess.open(UPGRADES_PATH)
	
	if dir:
		dir.list_dir_begin() # 开始遍历文件夹
		var file_name = dir.get_next() # 获取第一个文件名
		
		# 只要还有文件，就一直循环
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = UPGRADES_PATH + "/" + file_name
				var resource = load(full_path)
				# 安全检查：确保加载进来的真的是 UpgradeItem，而不是别的什么资源
				if resource is UpgradeItem:
					all_upgrades.append(resource)
			file_name = dir.get_next()
			
		dir.list_dir_end() # 结束遍历
	else:
		print("错误：找不到文件夹路径 " + UPGRADES_PATH)
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
	apply_upgrade_effect(item)
	visible = false
	Game.upgrade = false
	get_tree().paused = false
	Game.gain_research(0)

func apply_upgrade_effect(item: UpgradeItem):
	match item.id:
		"damage":
			Game.global_damage_bonus += item.value
		"speed":
			Game.global_speed_bonus += item.value
		"gold":
			Game.gain_gold(int(item.value))
