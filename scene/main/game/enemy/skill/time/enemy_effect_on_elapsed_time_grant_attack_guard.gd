class_name EnemyEffectOnElapsedTimeGrantAttackGuard
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 付与対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.SELF
# 無効回数
@export_range(1, 64, 1) var guard_count := 1
# 重複上限
@export_range(0, 64, 1) var stack_limit := 1
# 通常攻撃停止
@export var suppress_default_attack := false

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH): context.resolver.set_default_attack_disabled(context.source, suppress_default_attack); return
	if not context.is_event(Event.PROGRESS_TIME): return
	var count := context.consume_interval(interval_seconds) # 発火数
	for enemy in context.get_targets(target): context.resolver.add_attack_guards(enemy, mini(stack_limit, guard_count * count))
