class_name InputTerminal
extends Terminal

func get_value_at_time(t: float) -> float:
    if connection:
        return connection.get_value_at_time(t)
    return 0
    
func get_values_in_range(t: PackedFloat32Array) -> PackedFloat32Array:
    if connection:
        return connection.get_values_in_range(t)
    var r: PackedFloat32Array = []
    r.resize(len(t))
    r.fill(0.0)
    return r

func _to_string():
    return "InputTerminal[%s]" % component_name()