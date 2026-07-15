class_name EnemyEffectOnElapsedTimeRecoverAdjacent
extends EnemyEffectOnTimeProgressed



var enemies: Array[Enemy] = [] # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 回復量
@export var recovery := 0
# 自身を含む
@export var include_self := false
# 通常攻撃停止
@export var suppress_default_attack := false


# 通常攻撃停止判定
func suppresses_default_attack() -> bool:
	return suppress_default_attack

# 効果適用
func apply() -> void:
	var count := consume_interval(interval_seconds) # 発火数
	for enemy in EnemyEffectTargetQuery.get_adjacent_objects(source, enemies): EnemyEffectBattleActions.recover(source, enemy, recovery * count)
	if include_self: EnemyEffectBattleActions.recover(source, source, recovery * count)
