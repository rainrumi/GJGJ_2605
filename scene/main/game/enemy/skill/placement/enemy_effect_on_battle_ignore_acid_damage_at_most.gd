class_name EnemyEffectOnBattleIgnoreAcidDamageAtMost
extends EnemyEffect

# 閾値
@export var threshold := 0
# 閾値参照元
@export var threshold_source: EnemyEffect.ValueSource = EnemyEffect.ValueSource.FIXED

