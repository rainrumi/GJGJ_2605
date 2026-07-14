class_name EnemyEffectOnAdjacentWeakerAbsorbSkill
extends EnemyEffect

# 消化ダメージ
@export var damage := 0

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.REFRESH): return
	for enemy in runtime.get_new_adjacent_objects():
		if enemy.get_damage() < runtime.source.get_damage(): runtime.deal_acid_damage(enemy, damage); runtime.resolver.inherit_effects(runtime.source, enemy)
