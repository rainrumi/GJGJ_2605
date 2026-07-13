class_name EnemyEffectOnElapsedTimeGrantExtraAttack
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 付与対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS
# 追加攻撃数
@export_range(1, 64, 1) var extra_attack_count := 1
# 重複上限
@export_range(0, 64, 1) var stack_limit := 1
# 通常攻撃停止
@export var suppress_default_attack := false

