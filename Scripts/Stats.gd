extends Node
class_name Stats

# ====== 敌人类型 ======
const ENEMY = {
	"normal": { "base_hp": 60,  "speed": 100, "gold": 10 },
	"fast":   { "base_hp": 80,  "speed": 160, "gold": 12 },
	"tank":   { "base_hp": 240, "speed": 80,  "gold": 25 }
}

# 敌人 HP 随波增长倍率
const HP_GROWTH := 1.20

# 根据敌人类型 + 波次返回最终 HP
static func get_enemy_hp(enemy_type: String, wave: int) -> int:
	var base_hp := int(ENEMY[enemy_type]["base_hp"])
	return int(round(base_hp * pow(HP_GROWTH, wave - 1)))

static func get_enemy_speed(enemy_type: String) -> float:
	return ENEMY[enemy_type]["speed"]

static func get_enemy_gold(enemy_type: String) -> int:
	return ENEMY[enemy_type]["gold"]

# ====== 防御塔（可选扩展） ======
const TOWER = {
	"basic": {
		"cost": 50,
		"damage": 10,
		"interval": 0.5,
		"range": 160,
		"upgrade_cost": [50, 100, 200], # 升到 Lv2/Lv3/Lv4 的价格
		"dps_multiplier": 1.5
	}
}
