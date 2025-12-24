extends Label


func _process(delta):
	self.text = "下波出怪时间 " + str(int($"../../PathSpawner/Timer".time_left)) 
