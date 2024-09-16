class_name SquareWave
extends WaveForm


func get_value_at_time(t: float = 0) -> float:
    var wavelength = 1.0 / frequency
    if fmod(t, wavelength) > wavelength * 0.5:
        return amplitude
    return -amplitude


func _to_string():
    return "SquareWave(Hz:%s, A:%s, ω:%s)" % [frequency, amplitude, speed]
