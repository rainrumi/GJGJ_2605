class_name EnemyEffectOnElapsedTimeRecoverHp
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_progress_time(self)

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 固定回復量
@export var recovery := 0
# 割合回復量
@export var recovery_rate := 0.0

# 効果適用
func apply() -> void:
	var count := consume_interval(interval_seconds) # 発火数
	EnemyEffectBattleActions.recover(source, source, recovery * count, recovery_rate * count)
