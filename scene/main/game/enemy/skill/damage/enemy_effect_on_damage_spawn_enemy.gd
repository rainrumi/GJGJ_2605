class_name EnemyEffectOnDamageSpawnEnemy
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
# 生成HP
@export var spawn_hp := -1
# 生成攻撃力
@export var spawn_attack := -1

