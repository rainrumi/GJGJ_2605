class_name EnemyEffectOnAcidDamageCountAttack
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_AFTER_ACID_DAMAGE

# 必要被弾数
@export_range(1, 10000, 1) var required_count := 1
# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0

# 効果適用
func apply() -> void:
	if not is_after_acid_damage_activation() or get_activation_target() != source: return
	var count := get_state_int("hit_count") + 1 # 被弾数
	set_state("hit_count", count % required_count)
	if count >= required_count: attack_player(fixed_damage if fixed_damage > 0 else source.get_damage(), attack_count)
