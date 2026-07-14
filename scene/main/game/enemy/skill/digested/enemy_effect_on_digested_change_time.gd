class_name EnemyEffectOnDigestedChangeTime
extends EnemyEffectOnSelfDigested


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_digested(self)


var battle_clock: BattleClock # 効果依存


# 戦闘時刻設定
func setup_battle_clock(value: BattleClock) -> void:
	battle_clock = value


# 依存関係解除
func clear_dependencies() -> void:
	battle_clock = null

# 時刻秒差分
@export var seconds_delta := 0

# 効果適用
func apply() -> void:
	EnemyEffectWorldActions.add_time_delta(battle_clock, seconds_delta)
