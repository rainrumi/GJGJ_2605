class_name EnemyEffectOnAcidDamageRecoverAll
extends EnemyEffect

# 回復量
@export var recovery := 0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ALL_OBJECTS
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 失敗率扱い
@export var invert_chance := false

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.AFTER_ACID_DAMAGE) or context.target != context.source or not context.roll(chance, invert_chance): return
	for enemy in context.get_targets(target): context.recover(enemy, recovery)
