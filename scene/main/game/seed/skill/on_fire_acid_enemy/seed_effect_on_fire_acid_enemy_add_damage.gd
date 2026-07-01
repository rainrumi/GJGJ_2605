class_name SeedEffectOnFireAcidEnemyAddDamage
extends SeedEffect

@export var add_damage_rate := 0.0 # 加算率
@export var chance := 0 # 抽選間隔
@export var chance_damage_rate := 0.0 # 抽選率
@export var line_cell_damage_rate := 0.0 # 列セル率
@export var interval_minutes_rate := 0.0 # 間隔率


# 敵消化中
func on_fire_acid_enemy(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass
