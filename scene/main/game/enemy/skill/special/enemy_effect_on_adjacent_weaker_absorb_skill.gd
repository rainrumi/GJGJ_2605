class_name EnemyEffectOnAdjacentWeakerAbsorbSkill
extends EnemyEffect

# 消化ダメージ
@export var damage := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.REFRESH): return
	for enemy in context.get_new_adjacent_objects():
		if enemy.get_damage() < context.source.get_damage(): context.deal_acid_damage(enemy, damage); context.resolver.inherit_effects(context.source, enemy)
