class_name SineWave
extends WaveForm


func get_value_at_time(t: float = 0) -> float:
	var pos = t - (t * speed * 0.001)
	return sin(pos * frequency * TAU) * amplitude


func _to_string():
	return "SineWave(Hz:%s, A:%s, ω:%s)" % [frequency, amplitude, speed]
