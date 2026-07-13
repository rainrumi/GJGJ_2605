class_name EnemyEffectOnAcidDamageCountAttack
extends EnemyEffect

# 必要被弾数
@export_range(1, 10000, 1) var required_count := 1
# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.AFTER_ACID_DAMAGE) or context.target != context.source: return
	var count := context.get_state_int("hit_count") + 1 # 被弾数
	context.set_state("hit_count", count % required_count)
	if count >= required_count: context.attack_player(fixed_damage if fixed_damage > 0 else context.source.get_damage(), attack_count)
