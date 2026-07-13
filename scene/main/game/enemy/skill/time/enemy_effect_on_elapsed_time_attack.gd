class_name EnemyEffectOnElapsedTimeAttack
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0
# 通常攻撃停止
@export var suppress_default_attack := false
# ダメージ参照元
@export var damage_source: EnemyEffect.ValueSource = EnemyEffect.ValueSource.SELF_ATTACK

