extends Resource
class_name UpgradeItem

@export_group("显示信息") 
@export var title: String = "升级名称"
@export_multiline var description: String = "升级描述"
@export var icon: Texture2D # 用来存图标 (png/jpg)

@export_group("游戏数据")
@export_enum("damage", "speed", "gold", "health") var id: String = "damage" 
@export var value: int = 0.0
