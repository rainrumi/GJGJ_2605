class_name EnemyEffectOnAcidDamageAcquireAttack
extends EnemyEffect

# 取得割合
@export var attack_rate := 1.0
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# ライン接触必須
@export var require_acid_line_touch := false

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.AFTER_ACID_DAMAGE) or context.target != context.source: return
	if require_acid_line_touch and context.get_acid_line_contact_count() == 0: return
	if context.roll(chance): context.source.add_damage(roundi(float(context.damage) * attack_rate))
