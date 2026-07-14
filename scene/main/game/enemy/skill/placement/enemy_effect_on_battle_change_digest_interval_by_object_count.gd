class_name EnemyEffectOnBattleChangeDigestIntervalByObjectCount
extends EnemyEffect

# モノ毎秒差
@export var seconds_per_object := 0

# 効果適用
func apply() -> void:
	if is_refresh_activation(): add_interval_seconds(seconds_per_object * get_active_objects().size())
