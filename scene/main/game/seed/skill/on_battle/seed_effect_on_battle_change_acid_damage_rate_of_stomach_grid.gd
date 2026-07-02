class_name SeedEffectOnBattleChangeAcidDamageRateOfStomachGrid
extends SeedEffect

@export var amount := 10.0 # 乗算値


# 酸倍率取得
func get_acid_damage_rate(_state: DreamSeedSkillState, _context: Dictionary) -> float:
	var base_damage := int(_context.get("base_damage", 0)) # 基礎酸ダメ
	if base_damage <= 0:
		return 0.0
	var columns := int(_context.get("stomach_columns", 0)) # 胃袋列
	var rows := int(_context.get("stomach_rows", 0)) # 胃袋行
	return (float(columns * rows) * amount) / float(base_damage)
