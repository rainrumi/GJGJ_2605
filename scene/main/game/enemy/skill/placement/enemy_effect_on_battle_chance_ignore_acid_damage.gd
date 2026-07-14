class_name EnemyEffectOnBattleChanceIgnoreAcidDamage
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_BEFORE_ACID_DAMAGE

# 無効率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 失敗率扱い
@export var invert_chance := false

# 効果適用
func apply() -> void:
	if is_before_acid_damage_activation() and get_activation_target() == source and roll(chance, invert_chance): set_activation_damage(0)
