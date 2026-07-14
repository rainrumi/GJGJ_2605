class_name EnemyEffectEventSource
extends RefCounted

enum Phase {
	ALL,
	PREPROCESS,
	MAIN,
}

signal occurred(event_data: EnemyEffectEventData, enemies: Array[Enemy], stomach: StomachBoard, phase: Phase)


# イベント通知
func notify(event_data: EnemyEffectEventData, enemies: Array[Enemy], stomach: StomachBoard, phase := Phase.ALL) -> void:
	if event_data == null:
		return
	occurred.emit(event_data, enemies, stomach, phase)
