class_name EnemyEffectOnAcidDamageRecoverAll
extends EnemyEffect

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
	if not runtime.is_event(Event.AFTER_ACID_DAMAGE) or runtime.target != runtime.source or not runtime.roll(chance, invert_chance): return
	for enemy in runtime.get_targets(target): runtime.recover(enemy, recovery)
