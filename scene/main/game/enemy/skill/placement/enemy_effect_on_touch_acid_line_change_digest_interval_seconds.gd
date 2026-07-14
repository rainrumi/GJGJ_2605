class_name EnemyEffectOnTouchAcidLineChangeDigestIntervalSeconds
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_STOMACH | DEPENDENCY_DIGESTION_INTERVAL

# 秒差分
@export var interval_delta_seconds := 0

# 効果適用
func apply() -> void:
	if is_refresh_activation() and get_acid_line_contact_count() > 0: add_interval_seconds(interval_delta_seconds)
