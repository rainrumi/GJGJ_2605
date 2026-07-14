class_name EnemyEffectOnAcidDamageCountAttack
extends EnemyEffect

# 必要被弾数
@export_range(1, 10000, 1) var required_count := 1
# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.AFTER_ACID_DAMAGE) or runtime.target != runtime.source: return
	var count := runtime.get_state_int("hit_count") + 1 # 被弾数
	runtime.set_state("hit_count", count % required_count)
	if count >= required_count: runtime.attack_player(fixed_damage if fixed_damage > 0 else runtime.source.get_damage(), attack_count)
