extends Label


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	self.text = "科技点 " + str(Game.Ancient_Reasearch_points) + "/" + str(Game.xp_to_next_level)
