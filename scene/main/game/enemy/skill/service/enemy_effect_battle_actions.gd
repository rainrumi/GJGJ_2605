class_name EnemyEffectBattleActions
extends RefCounted


# プレイヤー攻撃
static func attack_player(source: Enemy, player_health: PlayerHealth, value: int, count := 1) -> void:
	if player_health == null:
		return
	for _index in range(maxi(0, count)):
		var damage := maxi(0, roundi(EnemyEffectValueCalculator.scale(source, float(value)))) # 攻撃値
		player_health.request_damage(damage)


# 消化ダメージ付与
static func deal_acid_damage(
	effect: EnemyEffect,
	digestion_state: EnemyDigestionState,
	enemy: Enemy,
	value: int,
	hit_count := 1
) -> void:
	if enemy == null or enemy.is_Acided() or value <= 0:
		return
	var activation := effect.get_activation_data() as DigestionActivationData # 消化発動値
	var digested: Array[Enemy] = [] # 消化済み一覧
	if activation != null:
		digested = activation.digested_enemies
	for _index in range(maxi(1, hit_count)):
		var damage := maxi(0, roundi(EnemyEffectValueCalculator.scale(effect.source, float(value)))) # 消化値
		if enemy.take_acid_damage(damage):
			if not digested.has(enemy):
				digested.append(enemy)
			if digestion_state != null:
				digestion_state.register(enemy)
			break


# 敵回復
static func recover(source: Enemy, enemy: Enemy, value: int, rate := 0.0) -> void:
	if enemy == null:
		return
	var amount := roundi(EnemyEffectValueCalculator.scale(source, float(value))) # 回復量
	amount += roundi(float(enemy.get_max_hp()) * EnemyEffectValueCalculator.scale(source, rate))
	enemy.heal(maxi(0, amount))


# 敵復活
static func revive(source: Enemy, enemy: Enemy, rate: float) -> void:
	if enemy != null and enemy.is_Acided():
		enemy.revive_with_hp_rate(clampf(EnemyEffectValueCalculator.scale(source, rate), 0.0, 1.0))
