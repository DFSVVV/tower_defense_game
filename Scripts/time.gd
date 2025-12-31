extends Label


func _process(_delta):
	if Game.WaveNow >= Game.WaveTotal:
		self.text = "下波出怪时间 0"
	else:
		self.text = "下波出怪时间 " + str(int($"../../PathSpawner/Timer".time_left))
