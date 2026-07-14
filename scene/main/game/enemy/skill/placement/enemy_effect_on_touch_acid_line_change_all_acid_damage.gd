class_name EnemyEffectOnTouchAcidLineChangeAllAcidDamage
extends EnemyEffect

# ダメージ差分
@export var damage_delta := 0
# ダメージ倍率
@export var damage_multiplier := 1.0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH) and runtime.get_acid_line_contact_count() > 0: runtime.add_global_acid_damage(damage_delta, damage_multiplier)
