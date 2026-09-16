class_name EnemyEffectOnAcidDamageChangeSelf
extends EnemyEffectOnSelfAfterAcidDamage


# HP差分
@export var hp_delta := 0
# 攻撃力差分
@export var attack_delta := 0


# 効果適用
func apply() -> void:
	if source == null:
		return
	source.current_hp += roundi(EnemyEffectValueCalculator.scale(source, float(hp_delta)))
	source.add_damage(roundi(EnemyEffectValueCalculator.scale(source, float(attack_delta))))
