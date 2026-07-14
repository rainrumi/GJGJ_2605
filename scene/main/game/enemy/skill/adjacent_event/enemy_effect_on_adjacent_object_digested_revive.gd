class_name EnemyEffectOnAdjacentObjectDigestedRevive
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_adjacent_digested(self)


var enemies: Array[Enemy] = [] # 効果依存
var stomach: StomachBoard # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()
	stomach = installer.get_stomach()


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	stomach = null

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0
# 復活対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 発動条件判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	return EnemyEffectTargetQuery.get_targets(source, enemies, stomach, target).has(get_activation_target_from(data))


# 効果適用
func apply() -> void:
	EnemyEffectBattleActions.revive(source, get_activation_target(), recovery_rate)
