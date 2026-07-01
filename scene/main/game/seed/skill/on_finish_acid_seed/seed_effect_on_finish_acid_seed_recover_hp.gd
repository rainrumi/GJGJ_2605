class_name SeedEffectOnFinishAcidSeedRecoverHp
extends SeedEffect

@export var hp_rate := 0.0 # HP率
@export var hp_rate_per_size := 0.0 # サイズ率
@export var hp_rate_from_minute := false # 分参照


# 種消化完了
func on_finish_acid_seed(_state: DreamSeedSkillState, _context: Dictionary) -> bool:
	return true
