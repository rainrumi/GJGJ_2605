class_name EnemyEffectOnProgressTimeDisableDefaultAttack
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)

# 通常攻撃停止
@export var disabled := true

# 効果適用
func apply() -> void:
	EnemyEffectStatChanges.set_default_attack_disabled(source, disabled)
