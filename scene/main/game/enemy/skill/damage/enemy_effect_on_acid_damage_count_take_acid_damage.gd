class_name EnemyEffectOnAcidDamageCountTakeAcidDamage
extends EnemyEffect

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
