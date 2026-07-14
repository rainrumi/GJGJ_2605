class_name EnemyEffectOnSelfOrAdjacentDigestedRevive
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_adjacent_digested(self)


var enemies: Array[Enemy] = [] # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0
# 生存者必須
@export var require_survivor := true
# 自身を含む
@export var include_self := true

# 発動条件判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	var group := EnemyEffectTargetQuery.get_adjacent_objects(source, enemies) # 共有群
	if include_self:
		group.append(source)
	if not group.has(get_activation_target_from(data)):
		return false
	return not require_survivor or group.any(func(enemy: Enemy) -> bool: return not enemy.is_Acided())


# 効果適用
func apply() -> void:
	EnemyEffectBattleActions.revive(source, get_activation_target(), recovery_rate)
