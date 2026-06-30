class_name BattleTurnResultData
extends RefCounted

var Acided_enemies: Array[Enemy] = []
var spawn_requests: Array[BattleSpawnEnemyData] = []
var player_damage_values: Array[int] = []
var extra_elapsed_minutes := 0
var time_override_minutes := -1
