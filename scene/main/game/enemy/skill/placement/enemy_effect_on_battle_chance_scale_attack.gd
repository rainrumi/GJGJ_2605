class_name EnemyEffectOnBattleChanceScaleAttack
extends EnemyEffectOnRefresh


# 攻撃倍率
@export var attack_multiplier := 1.0
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 無効率扱い
@export var invert_chance := false

# 効果適用
func apply() -> void:
	var active := get_state_int("active", -1) # 発動状態
	if active < 0: active = 1 if EnemyEffectValueCalculator.roll(source, chance, invert_chance) else 0; set_state("active", active)
	if active == 1: EnemyEffectStatChanges.multiply_attack(source, source, attack_multiplier)
