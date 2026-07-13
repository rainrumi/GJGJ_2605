class_name EnemyEffectOnBattleChanceScaleAttack
extends EnemyEffect

# 攻撃倍率
@export var attack_multiplier := 1.0
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 無効率扱い
@export var invert_chance := false

