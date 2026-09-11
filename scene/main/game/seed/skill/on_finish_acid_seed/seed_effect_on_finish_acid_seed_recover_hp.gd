class_name SeedEffectOnFinishAcidSeedRecoverHp
extends SeedEffect

@export var heal_per_damaged_object := 0
@export var hp_rate := 0.0 # HP率
@export var adjacent_digestion_only := false
@export var hp_rate_per_size := 0.0 # サイズ率
@export var hp_rate_from_minute := false # 分参照


# 種消化完了
func on_finish_acid_seed(_state: DreamSeedSkillState, _context: Dictionary) -> bool:
	return not adjacent_digestion_only


func get_adjacent_digestion_heal_rate() -> float:
	return hp_rate if adjacent_digestion_only else 0.0
