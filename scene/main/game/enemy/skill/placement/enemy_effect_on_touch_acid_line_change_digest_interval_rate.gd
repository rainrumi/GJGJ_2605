class_name EnemyEffectOnTouchAcidLineChangeDigestIntervalRate
extends EnemyEffect

# 割合差分
@export var interval_delta_rate := 0.0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH) and runtime.get_acid_line_contact_count() > 0: runtime.add_interval_rate(interval_delta_rate)
