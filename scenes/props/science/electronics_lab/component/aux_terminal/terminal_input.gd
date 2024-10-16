class_name AuxTerminalInput
extends AuxTerminal


func get_value_at_time(t: float) -> float:
    if _cable:
        return _cable.get_value_at_time(t)
    return 0


func get_values_in_range(t: PackedFloat32Array) -> PackedFloat32Array:
    if _cable:
        return _cable.get_values_in_range(t)
    return GameSignal.fill_zeroes(t)


func _to_string():
    return "AuxTerminalInput[%s]" % component_name()