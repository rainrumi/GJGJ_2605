class_name EnemyEffectOnTouchAcidLineChangeAttack
extends EnemyEffect

# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH) and runtime.get_acid_line_contact_count() > 0: runtime.add_attack_delta(runtime.source, attack_delta)
