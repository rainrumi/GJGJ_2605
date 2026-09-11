class_name SeedEffectOnAcidDamageChangeAcidDamageRateByStomachCount
extends SeedEffect

@export var rate := 1.5 # 変動率
@export var max_stomach_count := 3 # 胃内上限
@export var counts_enemies_only := false # 悪夢のみ数える


# 種消化完了
func on_finish_acid_seed(_state: DreamSeedSkillState, _context: Dictionary) -> bool:
	return true


# 消化後持続判定
func persists_after_seed_digested() -> bool:
	return true


# 消化率取得
func get_acid_damage_rate(_state: DreamSeedSkillState, context: Dictionary) -> float:
	var count_key := "stomach_enemy_count" if counts_enemies_only else "stomach_count"
	var stomach_count := int(context.get(count_key, 0)) # 胃内数
	if stomach_count <= max_stomach_count:
		return rate
	return 1.0
