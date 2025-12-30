extends Node2D


@onready var path = preload("res://MobsMove/GoblinMove.tscn")
@onready var timer = $Timer  # 获取定时器节点

# 定义波次信息
var waves = [
	{"monster_count": 5, "interval": 1.0},  # 第一波，5个怪物，每个怪物间隔1秒
	{"monster_count": 7, "interval": 1.2},  # 第二波，7个怪物，每个怪物间隔1.2秒
	{"monster_count": 10, "interval": 1.5}  # 第三波，10个怪物，每个怪物间隔1.5秒
]
var current_wave = 0  # 当前波次

func _ready():
	Game.WaveTotal = waves.size()
	Game.WaveNow = 0
	current_wave = 0
	timer.start(3.0)

func _on_timer_timeout():
	if current_wave < waves.size():
		var wave = waves[current_wave]
		current_wave += 1
		spawn_wave(wave)
		Game.WaveNow += 1

		if current_wave < waves.size():
			timer.start(20)
		else:
			timer.stop()
	else:
		timer.stop()


# 实例化怪物并加入场景
func spawn_wave(wave_data):
	var monster_count = wave_data["monster_count"]
	print(monster_count)
	Game.EnemyNum += monster_count
	for i in range(monster_count):
		var tempPath = path.instantiate()
		add_child(tempPath)
		await get_tree().create_timer(wave_data["interval"]).timeout

	
