class_name EnemyEffectOnAcidDamageCountTakeAcidDamage
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_AFTER_ACID_DAMAGE


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_DIGESTION_STATE

# 必要被弾数
@export_range(1, 10000, 1) var required_count := 1
# 追加ダメージ
@export var damage := 0

# 効果適用
func apply() -> void:
	if not is_after_acid_damage_activation() or get_activation_target() != source: return
	var count := get_state_int("hit_count") + 1 # 被弾数
	set_state("hit_count", count % required_count)
	if count >= required_count: deal_acid_damage(source, damage)
