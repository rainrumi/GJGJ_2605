class_name EnemyEffectOnBattleChanceScaleAttack
extends EnemyEffect

# 攻撃倍率
@export var attack_multiplier := 1.0
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 無効率扱い
@export var invert_chance := false

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.REFRESH): return
	var active := context.get_state_int("active", -1) # 発動状態
	if active < 0: active = 1 if context.roll(chance, invert_chance) else 0; context.set_state("active", active)
	if active == 1: context.multiply_attack(context.source, attack_multiplier)
