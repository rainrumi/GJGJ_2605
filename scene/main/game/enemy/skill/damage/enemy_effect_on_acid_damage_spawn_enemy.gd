class_name EnemyEffectOnAcidDamageSpawnEnemy
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
@export var spawn_area: EnemyEffect.SpawnArea = EnemyEffect.SpawnArea.EMPTY_STOMACH
# HP参照元
@export var hp_source: EnemyEffect.ValueSource = EnemyEffect.ValueSource.FIXED
# HP倍率
@export var hp_multiplier := 1.0
# 攻撃参照元
@export var attack_source: EnemyEffect.ValueSource = EnemyEffect.ValueSource.FIXED
# 攻撃倍率
@export var attack_multiplier := 1.0
# スキル継承
@export var inherit_skill := false
# 成功時HP倍率
@export var self_hp_multiplier_on_success := 1.0
# 成功時攻撃倍率
@export var self_attack_multiplier_on_success := 1.0

