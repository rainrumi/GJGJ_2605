class_name EnemyAttackResolver
extends RefCounted

const STEP_MINUTES := 30

var _seed_effects: SeedEffectResolver # 種効果計算
var _enemy_effects: EnemyEffectSystem # 敵効果窓口
var _base_acid_damage := 0 # setupで注入される基準消化値
var _battle_start_minutes := 0 # 戦闘開始分


# 依存関係設定
func setup(seed_effects: SeedEffectResolver, enemy_effects: EnemyEffectSystem, base_acid_damage: int) -> void:
	_seed_effects = seed_effects
	_enemy_effects = enemy_effects
	_base_acid_damage = maxi(0, base_acid_damage)


# 開始分設定
func set_battle_start_minutes(value: int) -> void:
	_battle_start_minutes = maxi(0, value)


# 敵攻撃解決
func resolve(enemies: Array[Enemy], stomach: StomachBoard, minutes: int) -> Array[int]:
	var raw_values: Array[int] = [] # 補正前一覧
	var total_damage := 0 # 補正前合計
	for enemy in enemies:
		if not enemy.should_deal_player_damage() or not enemy.can_take_stomach_turn():
			continue
		if enemy.data.defense_status.default_attack_disabled:
			continue
		var damage := get_enemy_attack_damage(enemy, enemies, stomach, minutes) # 敵攻撃値
		if damage <= 0:
			continue
		var attack_values: Array[int] = [] # 敵別攻撃値
		for _index in range(maxi(0, 1 + enemy.data.defense_status.extra_attack_count)):
			attack_values.append(damage)
		raw_values.append_array(attack_values)
		total_damage += _sum_damage_values(attack_values)
	var final_damage := _seed_effects.apply_player_damage(total_damage, _base_acid_damage) # 最終ダメージ
	var values := _split_damage_values(raw_values, final_damage) # 表示ダメージ
	values.append_array(_enemy_effects.consume_player_damage())
	return values


# 敵攻撃値取得
func get_enemy_attack_damage(
	enemy: Enemy,
	_enemies: Array[Enemy],
	_stomach: StomachBoard,
	minutes := 0
) -> int:
	var delta := _seed_effects.get_enemy_attack_delta(minutes, _battle_start_minutes, STEP_MINUTES) # 攻撃差分
	var damage := maxi(0, roundi(float(enemy.get_damage()) * _seed_effects.get_enemy_attack_multiplier()) + delta) # 基準攻撃
	return enemy.data.attack.get_modified_value(damage)


# ダメージ合計
func _sum_damage_values(values: Array[int]) -> int:
	var total := 0 # 合計値
	for damage in values:
		total += damage
	return total


# ダメージ分割
func _split_damage_values(raw_values: Array[int], final_damage: int) -> Array[int]:
	var values: Array[int] = [] # 分割結果
	if raw_values.is_empty() or final_damage <= 0:
		return values
	var raw_total := _sum_damage_values(raw_values) # 補正前合計
	var assigned := 0 # 割当済み値
	var cumulative_raw := 0 # 累積補正前値
	for damage in raw_values:
		cumulative_raw += damage
		var cumulative := roundi(float(cumulative_raw) / float(raw_total) * float(final_damage)) # 累積補正値
		var split_damage := maxi(0, cumulative - assigned) # 今回割当値
		if split_damage > 0:
			values.append(split_damage)
		assigned = cumulative
	return values
