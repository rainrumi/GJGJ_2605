class_name EnemyEffectOnBattleChangeDigestIntervalByObjectCount
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES | DEPENDENCY_DIGESTION_INTERVAL

# モノ毎秒差
@export var seconds_per_object := 0

# 効果適用
func apply() -> void:
	if is_refresh_activation(): add_interval_seconds(seconds_per_object * get_active_objects().size())
