class_name EnemyEffectOnElapsedTimeTakeAcidDamage
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_PROGRESS_TIME

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# ダメージ
@export var damage := 0

# 効果適用
func apply() -> void:
	if is_progress_time_activation(): deal_acid_damage(source, damage, consume_interval(interval_seconds))
