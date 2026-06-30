class_name SeedEffectOnFireAcidEnemyAddDamage
extends SeedEffect

@export var add_damage_rate := 0.0
@export var chance := 0
@export var chance_damage_rate := 0.0
@export var line_cell_damage_rate := 0.0
@export var interval_minutes_rate := 0.0


# 敵消化中
func on_fire_acid_enemy(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass
