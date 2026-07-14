class_name EnemyEffectOnElapsedTimeDealAllAcidDamage
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_PROGRESS_TIME


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES | DEPENDENCY_STOMACH | DEPENDENCY_DIGESTION_STATE

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
	if not is_progress_time_activation(): return
	var count := consume_interval(interval_seconds) # 発火数
	for enemy in get_targets(target): deal_acid_damage(enemy, damage, hit_count * count)
