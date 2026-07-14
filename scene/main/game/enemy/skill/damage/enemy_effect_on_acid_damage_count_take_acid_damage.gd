class_name EnemyEffectOnAcidDamageCountTakeAcidDamage
extends EnemyEffect

# 必要被弾数
@export_range(1, 10000, 1) var required_count := 1
# 追加ダメージ
@export var damage := 0

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.AFTER_ACID_DAMAGE) or runtime.target != runtime.source: return
	var count := runtime.get_state_int("hit_count") + 1 # 被弾数
	runtime.set_state("hit_count", count % required_count)
	if count >= required_count: runtime.deal_acid_damage(runtime.source, damage)
