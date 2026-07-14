class_name EnemyEffectOnAcidDamageAcquireAttack
extends EnemyEffect

# 取得割合
@export var attack_rate := 1.0
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# ライン接触必須
@export var require_acid_line_touch := false

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.AFTER_ACID_DAMAGE) or runtime.target != runtime.source: return
	if require_acid_line_touch and runtime.get_acid_line_contact_count() == 0: return
	if runtime.roll(chance): runtime.source.add_damage(roundi(float(runtime.damage) * attack_rate))
