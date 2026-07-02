class_name SeedEffectOnBattleChangeAcidDamageRateOfProgress
extends SeedEffect

@export var amount := 10.0 # 割る数値


# 酸倍率取得
func get_acid_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	var base_damage := int(_context.get("base_damage", 0)) # 基礎酸ダメ
	if base_damage <= 0 or amount == 0.0:
		return 0.0
	var minutes := float(int(_context.get("minutes", 0))) # 消化間隔
	return (minutes / amount) / float(base_damage)
