class_name EnemyEffectOnDigestedReviveIfOtherObject
extends EnemyEffectOnSelfDigested



var enemies: Array[Enemy] = [] # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0

# 効果適用
func apply() -> void:
	if EnemyEffectTargetQuery.get_active_objects(enemies).any(func(enemy: Enemy) -> bool: return enemy != source):
		EnemyEffectBattleActions.revive(source, source, recovery_rate)
