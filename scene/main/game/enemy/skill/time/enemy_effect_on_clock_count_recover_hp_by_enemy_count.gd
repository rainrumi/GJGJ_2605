class_name EnemyEffectOnClockCountRecoverHpByEnemyCount
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_progress_time(self)


var enemies: Array[Enemy] = [] # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 敵毎回復量
@export var recovery_per_enemy := 0
# 自身を含む
@export var include_self := true

# 効果適用
func apply() -> void:
	var count := get_state_int("clock_count") + 1 # 時刻回数
	set_state("clock_count", count % required_count)
	if count >= required_count:
		var enemy_count := EnemyEffectTargetQuery.get_active_enemies(enemies).size() # 敵数
		if not include_self: enemy_count = maxi(0, enemy_count - 1)
		EnemyEffectBattleActions.recover(source, source, recovery_per_enemy * enemy_count)
