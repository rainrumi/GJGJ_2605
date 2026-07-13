class_name EnemyEffectOnBattleChanceIgnoreAcidDamage
extends EnemyEffect

# 無効率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 失敗率扱い
@export var invert_chance := false

