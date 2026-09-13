class_name EnemyEffectOnDigestedSpawnEnemy
extends EnemyEffectOnSelfDigested



var spawn_queue: EnemySpawnQueue # 効果依存


# 生成要求設定
func setup_spawn_queue(value: EnemySpawnQueue) -> void:
	spawn_queue = value


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

# 消化時の受領ダメージを生成先の無効化閾値へ渡す
@export var pass_taken_damage_as_threshold := false

# 効果適用
func apply() -> void:
	var hp_value := hp_base + roundi(float(resolve_value(hp_source, 0)) * hp_multiplier) + hp_delta # 生成HP
	if hp_value <= 0:
		return
	var attack_value := attack_base + roundi(float(resolve_value(attack_source, 0)) * attack_multiplier) + attack_delta # 生成攻撃
	var spawn_info := enemy_info
	if pass_taken_damage_as_threshold:
		var digestion_damage := get_activation_damage() # 消化前に記録された受領値
		if enemy_info == null or enemy_info.main_skill == null:
			push_error("消化ダメージ継承先の悪夢スキルが未設定です: %s" % resource_path)
			return
		spawn_info = enemy_info.duplicate(false) as EnemyInfo
		var skill := enemy_info.main_skill.duplicate(false) as EnemySkill
		skill.effects = []
		var threshold_found := false
		for effect in enemy_info.main_skill.effects:
			var copied_effect := effect.duplicate(true) as EnemyEffect
			if copied_effect is EnemyEffectOnBattleIgnoreAcidDamageAtMost:
				(copied_effect as EnemyEffectOnBattleIgnoreAcidDamageAtMost).threshold_source = ValueSource.FIXED
				(copied_effect as EnemyEffectOnBattleIgnoreAcidDamageAtMost).threshold = digestion_damage
				threshold_found = true
			skill.effects.append(copied_effect)
		if not threshold_found:
			push_error("消化ダメージ継承先にダメージ無効化効果がありません: %s" % enemy_info.resource_path)
			return
		spawn_info.main_skill = skill
		spawn_info.description += "(消化ダメージ:%dダメージ)" % digestion_damage
	EnemyEffectWorldActions.spawn_enemy(self, spawn_queue, spawn_info, spawn_skill, spawn_count, max_spawn_count, spawn_area, hp_value, attack_value, inherit_skill)
