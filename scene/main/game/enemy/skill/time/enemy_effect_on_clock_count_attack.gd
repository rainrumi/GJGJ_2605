class_name EnemyEffectOnClockCountAttack
extends EnemyEffect

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.PROGRESS_TIME): return
	var count := context.get_state_int("clock_count") + 1 # 時刻回数
	context.set_state("clock_count", count % required_count)
	if count >= required_count: context.attack_player(fixed_damage if fixed_damage > 0 else context.source.get_damage(), attack_count)
