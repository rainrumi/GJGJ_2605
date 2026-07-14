class_name EnemyEffectOnDigestedChanceRevive
extends EnemyEffect

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 失敗率扱い
@export var invert_chance := false
# 段階確率差
@export_range(-1.0, 1.0, 0.01) var chance_delta := 0.0
# 段階復活数
@export_range(0, 10000, 1) var revives_per_step := 0

# 効果適用
func apply() -> void:
	if not is_digested_activation() or get_activation_target() != source: return
	var steps := 0 if revives_per_step <= 0 else int(source.get_revive_count() / revives_per_step) # 段階数
	if roll(chance + chance_delta * steps, invert_chance): revive(source, recovery_rate)
