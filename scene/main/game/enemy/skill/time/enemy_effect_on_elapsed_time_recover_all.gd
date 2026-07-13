class_name EnemyEffectOnElapsedTimeRecoverAll
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 回復量
@export var recovery := 0
# 自身を含む
@export var include_self := true
# 通常攻撃停止
@export var suppress_default_attack := false

