class_name EnemyEffectOnClockCountRecoverHp
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_progress_time(self)

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 回復量
@export var recovery := 0

# 効果適用
func apply() -> void:
	var count := get_state_int("clock_count") + 1 # 時刻回数
	set_state("clock_count", count % required_count)
	if count >= required_count: EnemyEffectBattleActions.recover(source, source, recovery)
