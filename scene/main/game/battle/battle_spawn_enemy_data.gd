class_name BattleSpawnEnemyData
extends RefCounted

var source_enemy: Enemy
var enemy_info: EnemyInfo
var main_skill: EnemySkill
var spawn_area: EnemyEffect.SpawnArea = EnemyEffect.SpawnArea.SAME_CELLS
var cell := Vector2i.ZERO
var hp_rate := 0.5
var max_hp := -1
var current_hp := -1
var damage := 0
var acid_damage_rate := 1.0
var global_acid_damage_rate := 1.0
