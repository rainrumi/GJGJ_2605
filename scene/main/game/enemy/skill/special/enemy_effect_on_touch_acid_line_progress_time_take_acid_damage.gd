class_name EnemyEffectOnTouchAcidLineProgressTimeTakeAcidDamage
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_PROGRESS_TIME

# 固定ダメージ
@export var damage := 0
# 接触毎ダメージ
@export var damage_per_contact := 0

# 効果適用
func apply() -> void:
	if is_progress_time_activation(): deal_acid_damage(source, damage + damage_per_contact * get_acid_line_contact_count())
