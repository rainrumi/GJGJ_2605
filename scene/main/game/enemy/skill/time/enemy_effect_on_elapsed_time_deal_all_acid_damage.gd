class_name EnemyEffectOnElapsedTimeDealAllAcidDamage
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ALL_OBJECTS
# ダメージ
@export var damage := 0
# 攻撃回数
@export_range(1, 64, 1) var hit_count := 1

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.PROGRESS_TIME): return
	var count := runtime.consume_interval(interval_seconds) # 発火数
	for enemy in runtime.get_targets(target): runtime.deal_acid_damage(enemy, damage, hit_count * count)
