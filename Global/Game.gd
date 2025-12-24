extends Node

var Ancient_Reasearch_points
var Health
var Gold
var WaveTotal #总波数
var WaveNow #当前波数
var EnemyNum
var current_level
var xp_to_next_level
var global_damage_bonus
var global_speed_bonus 

signal level_up_ready #升级信号
# 尝试花费金币
func try_spend_gold(amount: int) -> bool:
	if Gold >= amount:
		Gold -= amount
		return true
	return false
	
func gain_gold(amount:int):
	Gold += amount

# 获得研究点
func gain_research(amount: int):
	Ancient_Reasearch_points += amount
	if Ancient_Reasearch_points >= xp_to_next_level:
		Ancient_Reasearch_points -= xp_to_next_level
		current_level += 1
		xp_to_next_level = int(xp_to_next_level * 2)
		emit_signal("level_up_ready") # 通知主场景弹出三选一
