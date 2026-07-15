class_name EnemyEffectOnAcidDamageChanceScaleTakenDamage
extends EnemyEffectOnSelfBeforeAcidDamage


# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# ダメージ倍率
@export var damage_multiplier := 1.0

# 発動条件判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	return super.accepts_activation(data) and EnemyEffectValueCalculator.roll(source, chance)


# 効果適用
func apply() -> void:
	set_activation_damage(roundi(float(get_activation_damage()) * damage_multiplier))
