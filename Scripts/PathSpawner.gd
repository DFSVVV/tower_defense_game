extends Node2D
class_name PathSpawner

@export var goblin_move_scene: PackedScene = preload("res://MobsMove/GoblinMove.tscn")
@export var demon_move_scene: PackedScene = preload("res://MobsMove/DemonMove.tscn")
@export var baseenemy_move_scene: PackedScene = preload("res://MobsMove/BaseMove1.tscn")

@export var path: Path2D

@onready var timer = $Timer  # 获取定时器节点
const HP_GROWTH := 1.20

const ENEMY = {
	"baseenemy": { "base_hp": 60,  "speed": 100, "gold": 10 },
	"goblin":  { "base_hp": 80,  "speed": 160, "gold": 12 },  # 快怪
	"demon":   { "base_hp": 240, "speed": 80,  "gold": 25 }
}
# 定义波次信息
var waves := [
	{ "baseenemy": 6, "goblin": 0, "demon": 0, "interval": 1.0 },  # 1
	{ "baseenemy": 7, "goblin": 0, "demon": 0, "interval": 1.0 },  # 2
	{ "baseenemy": 6, "goblin": 2, "demon": 0, "interval": 0.9 },  # 3
	{ "baseenemy": 6, "goblin": 2, "demon": 0, "interval": 0.9 },  # 4
	{ "baseenemy": 6, "goblin": 3, "demon": 0, "interval": 0.85 }, # 5
	{ "baseenemy": 7, "goblin": 3, "demon": 1, "interval": 0.85 }, # 6
	{ "baseenemy": 7, "goblin": 3, "demon": 1, "interval": 0.8 },  # 7
	{ "baseenemy": 8, "goblin": 3, "demon": 2, "interval": 0.8 },  # 8
	{ "baseenemy": 8, "goblin": 4, "demon": 2, "interval": 0.75 }, # 9
	{ "baseenemy": 8, "goblin": 5, "demon": 3, "interval": 0.75 }  # 10
]
var current_wave = 0  # 当前波次
var spawning := false


func find_parent_path2d() -> Path2D:
	var node: Node = self
	while node != null:
		if node is Path2D:
			return node
		node = node.get_parent()
	return null

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


func spawn_wave(wave_data: Dictionary) -> void:
	var interval: float = wave_data["interval"]
	var queue: Array[String] = []
	
	for i in range(wave_data.get("baseenemy", 0)):
		queue.append("baseenemy")
	for i in range(wave_data.get("goblin", 0)):
		queue.append("goblin")
	for i in range(wave_data.get("demon", 0)):
		queue.append("demon")


	queue.shuffle()

	Game.EnemyNum += queue.size()

	for enemy_type in queue:
		spawn_one(enemy_type, Game.WaveNow)
		await get_tree().create_timer(interval).timeout

func spawn_one(enemy_type: String, wave_no: int) -> void:
	var move_scene: PackedScene = null
	match enemy_type:
		"baseenemy":
			move_scene = baseenemy_move_scene
		"goblin":
			move_scene = goblin_move_scene
		"demon":
			move_scene = demon_move_scene

	if move_scene == null:
		push_error("缺少 enemy_type 对应的场景: " + enemy_type)
		return

	#wrapper 是 Node2D（GoblinMove/DemonMove/TankMove）
	var wrapper: Node = move_scene.instantiate()

	#wrapper 里必须有 Follow (PathFollow2D)
	var mover: PathFollow2D = wrapper.get_node_or_null("Follow") as PathFollow2D
	if mover == null:
		push_error("Move 场景缺少 Follow 节点: " + enemy_type)
		wrapper.queue_free()
		return

	#mover 里面要找到 BaseEnemy（可能不是第一个子节点，所以用递归查）
	var enemy: BaseEnemy = find_enemy(mover)
	if enemy == null:
		push_error("Follow 里找不到 BaseEnemy: " + enemy_type)
		# wrapper 已经没用了
		wrapper.queue_free()
		return

	var hp := get_enemy_hp(enemy_type, wave_no)
	enemy.health = hp
	enemy.speed = ENEMY[enemy_type]["speed"]
	enemy.gold_reward = ENEMY[enemy_type]["gold"]
	#把 mover 从 wrapper 拆下来，再挂到 Path2D
	wrapper.remove_child(mover)
	path.add_child(mover)
	mover.progress = 0.0
	wrapper.queue_free()

func get_enemy_hp(enemy_type: String, wave: int) -> int:
	var base_hp := int(ENEMY[enemy_type]["base_hp"])
	return int(round(base_hp * pow(HP_GROWTH, wave - 1)))

#递归找到 mover 下第一个 BaseEnemy
func find_enemy(node: Node) -> BaseEnemy:
	for child in node.get_children():
		if child is BaseEnemy:
			return child
		var deeper = find_enemy(child)
		if deeper != null:
			return deeper
	return null


## 实例化怪物并加入场景
#func spawn_wave(wave_data):
	#var monster_count = wave_data["monster_count"]
	#print(monster_count)
	#Game.EnemyNum += monster_count
	#for i in range(monster_count):
		#var tempPath = mob_move_scene.instantiate()
		#add_child(tempPath)
		#await get_tree().create_timer(wave_data["interval"]).timeout

	
