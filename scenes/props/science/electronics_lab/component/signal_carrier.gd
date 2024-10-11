class_name SignalCarrier3D
extends RigidBody3D

func get_value_at_time(_t: float) -> float:
    return 0
    
func get_values_in_range(t: PackedFloat32Array) -> PackedFloat32Array:
    var r: PackedFloat32Array = []
    r.resize(len(t))
    for i in len(t):
        r[i] = (get_value_at_time(t[i]))
    return r