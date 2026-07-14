class_name EnemyEffectOnBattleIgnoreAcidDamageBelow
extends EnemyEffect

# 閾値
@export var threshold := 0
# 閾値参照元
@export var threshold_source: EnemyEffect.ValueSource = EnemyEffect.ValueSource.FIXED

# 効果適用
func apply() -> void:
	if is_before_acid_damage_activation() and get_activation_target() == source and get_activation_damage() < resolve_value(threshold_source, threshold): set_activation_damage(0)
