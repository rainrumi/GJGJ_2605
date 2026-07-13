class_name EnemyEffectOnClockCountScaleAllAttack
extends EnemyEffect

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 攻撃倍率
@export var attack_multiplier := 1.0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ALL_OBJECTS

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.PROGRESS_TIME): return
	var count := context.get_state_int("clock_count") + 1 # 時刻回数
	context.set_state("clock_count", count % required_count)
	if count >= required_count:
		for enemy in context.get_targets(target): enemy.set_damage_value(roundi(float(enemy.get_damage()) * context.scale_value(attack_multiplier)))
