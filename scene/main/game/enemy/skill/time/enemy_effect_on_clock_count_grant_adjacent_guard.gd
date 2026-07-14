class_name EnemyEffectOnClockCountGrantAdjacentGuard
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_progress_time(self)


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

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 無効回数
@export_range(1, 64, 1) var guard_count := 1
# 付与対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply() -> void:
	var count := get_state_int("clock_count") + 1 # 時刻回数
	set_state("clock_count", count % required_count)
	if count >= required_count:
		for enemy in EnemyEffectTargetQuery.get_targets(source, enemies, stomach, target): EnemyEffectStatChanges.add_acid_guards(enemy, guard_count)
