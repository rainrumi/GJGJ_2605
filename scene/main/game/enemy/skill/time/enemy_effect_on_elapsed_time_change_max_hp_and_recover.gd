class_name EnemyEffectOnElapsedTimeChangeMaxHpAndRecover
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_progress_time(self)

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 最大HP差分
@export var max_hp_delta := 0
# 回復量
@export var recovery := 0

# 効果適用
func apply() -> void:
	var count := consume_interval(interval_seconds) # 発火数
	source.add_max_hp(roundi(EnemyEffectValueCalculator.scale(source, float(max_hp_delta * count))), false)
	EnemyEffectBattleActions.recover(source, source, recovery * count)
