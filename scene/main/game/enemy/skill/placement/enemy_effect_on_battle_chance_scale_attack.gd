class_name EnemyEffectOnBattleChanceScaleAttack
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH

# 攻撃倍率
@export var attack_multiplier := 1.0
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 無効率扱い
@export var invert_chance := false

# 効果適用
func apply() -> void:
	if not is_refresh_activation(): return
	var active := get_state_int("active", -1) # 発動状態
	if active < 0: active = 1 if roll(chance, invert_chance) else 0; set_state("active", active)
	if active == 1: multiply_attack(source, attack_multiplier)
