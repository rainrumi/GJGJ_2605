extends SceneTree

var _failures := 0 # 失敗数


class TestView:
	extends EnemyView

	var shown_hp := -1 # HP表示値
	var shown_attack := -1 # 攻撃表示値
	var damage_pulses := 0 # 被弾演出数
	var heal_pulses := 0 # 回復演出数
	var digestion_plays := 0 # 消化演出数
	var revive_plays := 0 # 復活演出数
	var damage_batches := 0 # 被弾一覧数


	# HP表示更新
	func show_hp(value: int) -> void:
		shown_hp = value


	# 攻撃表示更新
	func show_damage(value: int) -> void:
		shown_attack = value


	# 被弾演出
	func pulse_damage() -> void:
		damage_pulses += 1


	# 回復演出
	func pulse_hp() -> void:
		heal_pulses += 1


	# 消化演出
	func play_digested() -> void:
		digestion_plays += 1


	# 復活演出
	func show_revived() -> void:
		revive_plays += 1


	# 被弾一覧表示
	func show_damage_values(_values: Array) -> void:
		damage_batches += 1


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# Presenter試験
func _run() -> void:
	var owner := Enemy.new() # 表示対象敵
	var other := Enemy.new() # 別表示敵
	var model := owner.data # 敵Model
	model.hp.setup(10)
	model.attack.setup(3)
	var view := TestView.new() # 試験View
	var presenter := EnemyPresenter.new() # 表示仲介
	presenter.bind(model, view)
	_expect(view.shown_hp == 10, "bind時にHPを表示する")
	_expect(view.shown_attack == 3, "bind時に攻撃力を表示する")
	model.hp.take_damage(4)
	_expect(view.shown_hp == 6 and view.damage_pulses == 1, "被弾Signalを表示へ反映する")
	model.hp.heal(2)
	_expect(view.shown_hp == 8 and view.heal_pulses == 1, "回復Signalを表示へ反映する")
	model.attack.add_value(2)
	_expect(view.shown_attack == 5, "攻撃Signalを表示へ反映する")
	model.stomach_status.set_digested(true)
	model.stomach_status.set_digested(false)
	_expect(view.digestion_plays == 1 and view.revive_plays == 1, "消化状態を表示へ反映する")
	var other_result := EnemyDigestionResult.new() # 別敵結果
	other_result.enemy = other
	other_result.damage_values = [3]
	presenter.present_digestion_result(other_result)
	_expect(view.damage_batches == 0, "別Enemyの結果を自身のViewへ表示しない")
	var own_result := EnemyDigestionResult.new() # 自身結果
	own_result.enemy = owner
	own_result.damage_values = [4]
	presenter.present_digestion_result(own_result)
	_expect(view.damage_batches == 1, "自身の結果だけをViewへ表示する")
	var presenter_source := FileAccess.get_file_as_string(
		"res://scene/object/enemy/enemy_presenter.gd"
	) # Presenterソース
	_expect(not presenter_source.contains("result.enemy.enemy_view"), "Presenterが他Enemy Viewを参照しない")
	presenter.unbind()
	model.attack.add_value(1)
	_expect(view.shown_attack == 5, "unbind後はSignalを受信しない")
	view.free()
	owner.free()
	other.free()
	quit(_failures)


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyPresenterTest: %s" % message)
