class_name EnemyEffectOnBattleChanceIgnoreAcidDamage
extends EnemyEffect

# 無効率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 失敗率扱い
@export var invert_chance := false

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.BEFORE_ACID_DAMAGE) and runtime.target == runtime.source and runtime.roll(chance, invert_chance): runtime.damage = 0
