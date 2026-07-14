class_name EnemyEffectOnNotAdjacentAcidLineChangeAcidDamage
extends EnemyEffect

# ダメージ差分
@export var acid_damage_delta := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH) and runtime.get_acid_line_contact_count() == 0: runtime.add_acid_damage_delta(runtime.source, acid_damage_delta)
