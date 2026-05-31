extends TextureRect

@export var float_distance := 5.0
@export var float_period := 6.4

var _base_y := 0.0
var _float_time := 0.0


func _ready() -> void:
	_base_y = position.y


func _process(delta: float) -> void:
	_float_time += delta
	position.y = _base_y + sin(_float_time * TAU / max(float_period, 0.001)) * float_distance
