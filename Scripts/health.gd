extends Label


func _process(_delta):
	self.text = "生命值 " + str(Game.Health) 
