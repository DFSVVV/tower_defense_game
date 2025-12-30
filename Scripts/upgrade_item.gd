extends Resource
class_name UpgradeItem

@export_group("显示信息") 
@export var title: String = "升级名称"
@export_multiline var description: String = "升级描述"
@export var icon: Texture2D

@export_group("游戏数据")
@export_enum(
	"damage",
	"speed",
	"gold",
	"health",
	"pierce",      


	"crit",
	"crit_mul",    
	"wave_gold",   

) var id: String = "damage"

@export var value: float = 0.0
