class_name SeedEffectOnPlayerDamageChangeFlatAcidRate
extends SeedEffect

@export var flat_acid_rate := 0.0 # 固定酸率


# 被撃酸加算
func get_taken_attack_flat_acid_bonus(_state: DreamSeedSkillState, context: Dictionary) -> int:
	return floori(float(int(context.get("taken_damage", 0))) * flat_acid_rate)
