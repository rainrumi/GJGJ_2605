class_name EnemyEffectOnAwayAcidLineChangeAcidDamage
extends EnemyEffect

# ダメージ差分
@export var acid_damage_delta := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH) and context.get_acid_line_contact_count() == 0: context.add_acid_damage_delta(context.source, acid_damage_delta)
