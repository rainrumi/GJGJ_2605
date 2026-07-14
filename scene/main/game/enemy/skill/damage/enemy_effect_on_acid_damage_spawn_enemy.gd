class_name EnemyEffectOnAcidDamageSpawnEnemy
extends EnemyEffectOnSelfAfterAcidDamage


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_after_acid_damage(self)


var spawn_queue: EnemySpawnQueue # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	spawn_queue = installer.get_spawn_queue()


# 依存関係解除
func clear_dependencies() -> void:
	spawn_queue = null

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

# 効果適用
func apply() -> void:
	var hp_value := roundi(float(resolve_value(hp_source)) * hp_multiplier) # 生成HP
	var attack_value := roundi(float(resolve_value(attack_source)) * attack_multiplier) # 生成攻撃
	EnemyEffectWorldActions.spawn_enemy(self, spawn_queue, enemy_info, spawn_skill, spawn_count, max_spawn_count, spawn_area, hp_value, attack_value, inherit_skill)
	source.set_hp_values(roundi(float(source.get_max_hp()) * self_hp_multiplier_on_success), mini(source.get_current_hp(), roundi(float(source.get_max_hp()) * self_hp_multiplier_on_success)))
	source.set_damage_value(roundi(float(source.get_damage()) * self_attack_multiplier_on_success))
