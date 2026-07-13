class_name EnemyEffectOnDigestedChanceRevive
extends EnemyEffect

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 失敗率扱い
@export var invert_chance := false
# 段階確率差
@export_range(-1.0, 1.0, 0.01) var chance_delta := 0.0
# 段階復活数
@export_range(0, 10000, 1) var revives_per_step := 0

