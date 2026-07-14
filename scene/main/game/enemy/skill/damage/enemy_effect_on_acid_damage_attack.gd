class_name EnemyEffectOnAcidDamageAttack
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_AFTER_ACID_DAMAGE

# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0

# 効果適用
func apply() -> void:
	if is_after_acid_damage_activation() and get_activation_target() == source: attack_player(fixed_damage if fixed_damage > 0 else source.get_damage(), attack_count)
