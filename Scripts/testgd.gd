extends BaseTower


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()


func shoot(target_node):
	print("重写")
	super.Shoot(target_node)
