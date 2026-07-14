class_name EnemyEffectOnDigestedSpawnEnemy
extends EnemyEffect

# 生成敵定義
@export var enemy_info: EnemyInfo
# 生成スキル
@export var spawn_skill: EnemySkill
# 生成数
@export_range(1, 64, 1) var spawn_count := 1
# 生成上限
@export_range(0, 64, 1) var max_spawn_count := 0
# 生成範囲
@export var spawn_area: EnemyEffect.SpawnArea = EnemyEffect.SpawnArea.SAME_CELLS
# HP参照元
@export var hp_source: EnemyEffect.ValueSource = EnemyEffect.ValueSource.FIXED
# HP基準値
@export var hp_base := 0
# HP倍率
@export var hp_multiplier := 1.0
# HP差分
@export var hp_delta := 0
# 攻撃参照元
@export var attack_source: EnemyEffect.ValueSource = EnemyEffect.ValueSource.FIXED
# 攻撃基準値
@export var attack_base := 0
# 攻撃倍率
@export var attack_multiplier := 1.0
# 攻撃差分
@export var attack_delta := 0
# スキル継承
@export var inherit_skill := false

# 効果適用
func apply() -> void:
	if not is_digested_activation() or get_activation_target() != source: return
	var hp_value := hp_base + roundi(float(resolve_value(hp_source, 0)) * hp_multiplier) + hp_delta # 生成HP
	var attack_value := attack_base + roundi(float(resolve_value(attack_source, 0)) * attack_multiplier) + attack_delta # 生成攻撃
	spawn_enemy(enemy_info, spawn_skill, spawn_count, max_spawn_count, spawn_area, hp_value, attack_value, inherit_skill)
