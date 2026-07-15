class_name EnemyPresentationCoordinator
extends RefCounted

var _attack_resolver: EnemyAttackResolver # 攻撃値計算
var _presenters: Dictionary = {} # Model別Presenter


# 依存関係設定
func setup(attack_resolver: EnemyAttackResolver) -> void:
	_attack_resolver = attack_resolver


# Presenter同期
func sync(enemies: Array[Enemy]) -> void:
	_presenters.clear()
	for enemy in enemies:
		if enemy != null:
			_presenters[enemy.data] = enemy.get_presenter()


# 消化結果表示
func present_digestion_result(result: EnemyDigestionResult) -> void:
	if result == null or result.enemy == null:
		return
	var presenter: EnemyPresenter = _presenters.get(result.enemy.data) # 対象Presenter
	if presenter != null:
		presenter.present_digestion_result(result)


# 攻撃表示更新
func refresh_attack_displays(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes := 0
) -> void:
	sync(enemies)
	for enemy in enemies:
		if enemy == null or enemy.is_Acided():
			continue
		var presenter: EnemyPresenter = _presenters.get(enemy.data) # 対象Presenter
		if presenter == null:
			continue
		var display_damage := _attack_resolver.get_enemy_attack_damage(
			enemy,
			enemies,
			stomach,
			minutes
		) # 表示攻撃値
		presenter.set_attack_display(display_damage)
