class_name EnemyEffectOnClockCountDealAllAcidDamage
extends EnemyEffect

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ALL_OBJECTS
# ダメージ
@export var damage := 0
# 攻撃回数
@export_range(1, 64, 1) var hit_count := 1

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.PROGRESS_TIME): return
	var count := runtime.get_state_int("clock_count") + 1 # 時刻回数
	runtime.set_state("clock_count", count % required_count)
	if count >= required_count:
		for enemy in runtime.get_targets(target): runtime.deal_acid_damage(enemy, damage, hit_count)
