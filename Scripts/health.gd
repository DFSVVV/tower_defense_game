extends Label


func _process(delta):
	self.text = "生命值 " + str(Game.Health) 
