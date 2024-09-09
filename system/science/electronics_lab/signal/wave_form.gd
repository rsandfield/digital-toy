class_name WaveForm
extends GameSignal

@export var amplitude: float
@export var frequency: float
@export var speed: float
@export var offset: float


func _init(a: float = 1, f: float = 440, s: float = 0, o: float = 0):
	amplitude = a
	frequency = f
	speed = s
	offset = o


func get_value_at_time(_t: float = 0) -> float:
	assert(false, "Function not implemented")
	return 0


func _to_string():
	return "WaveForm(Hz:%s, A:%s, ω:%s)" % [frequency, amplitude, speed]
