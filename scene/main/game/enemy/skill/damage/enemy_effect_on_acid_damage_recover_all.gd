class_name EnemyEffectOnAcidDamageRecoverAll
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_AFTER_ACID_DAMAGE


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES | DEPENDENCY_STOMACH

# 回復量
@export var recovery := 0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ALL_OBJECTS
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 失敗率扱い
@export var invert_chance := false

# 効果適用
func apply() -> void:
	if not is_after_acid_damage_activation() or get_activation_target() != source or not roll(chance, invert_chance): return
	for enemy in get_targets(target): recover(enemy, recovery)
