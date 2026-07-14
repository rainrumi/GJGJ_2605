class_name EnemyEffectOnDigestionCountAttack
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_ANY_DIGESTED


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_PLAYER_HEALTH

# 必要消化数
@export_range(1, 10000, 1) var required_count := 1
# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0

# 効果適用
func apply() -> void:
	if not is_any_digested_activation(): return
	var count := get_state_int("digestion_count") + get_activation_digested_enemies().size() # 消化数
	var triggers := int(count / required_count) # 発火数
	set_state("digestion_count", count % required_count)
	attack_player(fixed_damage if fixed_damage > 0 else source.get_damage(), attack_count * triggers)
