class_name EnemyEffectOnAdjacentWeakerAbsorbHp
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES | DEPENDENCY_DIGESTION_STATE

# 消化ダメージ
@export var damage := 0

# 効果適用
func apply() -> void:
	if not is_refresh_activation(): return
	for enemy in get_new_adjacent_objects():
		if enemy.get_damage() < source.get_damage(): deal_acid_damage(enemy, damage); source.heal(enemy.get_current_hp())
