class_name EnemyEffectOnClockCountAttack
extends EnemyEffect

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.PROGRESS_TIME): return
	var count := runtime.get_state_int("clock_count") + 1 # 時刻回数
	runtime.set_state("clock_count", count % required_count)
	if count >= required_count: runtime.attack_player(fixed_damage if fixed_damage > 0 else runtime.source.get_damage(), attack_count)
