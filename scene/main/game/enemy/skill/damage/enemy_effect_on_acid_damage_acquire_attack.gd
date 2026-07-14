class_name EnemyEffectOnAcidDamageAcquireAttack
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_AFTER_ACID_DAMAGE

# 取得割合
@export var attack_rate := 1.0
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# ライン接触必須
@export var require_acid_line_touch := false

# 効果適用
func apply() -> void:
	if not is_after_acid_damage_activation() or get_activation_target() != source: return
	if require_acid_line_touch and get_acid_line_contact_count() == 0: return
	if roll(chance): source.add_damage(roundi(float(get_activation_damage()) * attack_rate))
