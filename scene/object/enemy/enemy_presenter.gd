class_name EnemyPresenter
extends RefCounted

var _attack_resolver: EnemyAttackResolver # 攻撃値計算


# 依存関係設定
func setup(attack_resolver: EnemyAttackResolver) -> void:
	_attack_resolver = attack_resolver


# 攻撃表示更新
func refresh_attack_displays(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes := 0
) -> void:
	for enemy in enemies:
		if enemy == null or enemy.is_Acided():
			continue
		var display_damage := _attack_resolver.get_enemy_attack_damage(enemy, enemies, stomach, minutes) # 表示攻撃値
		enemy.set_display_damage(display_damage)
