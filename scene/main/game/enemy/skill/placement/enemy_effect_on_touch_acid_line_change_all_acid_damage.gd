class_name EnemyEffectOnTouchAcidLineChangeAllAcidDamage
extends EnemyEffect

# ダメージ差分
@export var damage_delta := 0
# ダメージ倍率
@export var damage_multiplier := 1.0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH) and context.get_acid_line_contact_count() > 0: context.add_global_acid_damage(damage_delta, damage_multiplier)
