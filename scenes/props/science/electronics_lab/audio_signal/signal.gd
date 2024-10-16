class_name GameSignal
extends Resource


static func fill_zeroes(t: PackedFloat32Array) -> PackedFloat32Array:
    var r: PackedFloat32Array = []
    r.resize(len(t))
    r.fill(0.0)
    return r


func get_value_at_time(_t: float) -> float:
    assert(false, "Function not implemented")
    return 0


func get_values_in_range(t: PackedFloat32Array) -> PackedFloat32Array:
    var r: PackedFloat32Array = []
    r.resize(len(t))
    for i in len(t):
        r[i] = (get_value_at_time(t[i]))
    return r


func _to_string():
    return "GameSignal"
