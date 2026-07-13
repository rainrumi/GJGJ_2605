class_name EnemyEffectOnTouchAcidLineChangeAttack
extends EnemyEffect

# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH) and context.get_acid_line_contact_count() > 0: context.add_attack_delta(context.source, attack_delta)
