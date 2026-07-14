class_name EnemyEffectOnAdjacentWeakerAbsorbSkill
extends EnemyEffect

# 消化ダメージ
@export var damage := 0

# 効果適用
func apply() -> void:
	if not is_refresh_activation(): return
	for enemy in get_new_adjacent_objects():
		if enemy.get_damage() < source.get_damage(): deal_acid_damage(enemy, damage); inherit_effects(source, enemy)
