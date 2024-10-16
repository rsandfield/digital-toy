class_name AuxTerminalOutput
extends AuxTerminal


func get_value_at_time(t: float) -> float:
    if component:
        return component.get_value_at_time(t)
    return 0


func get_values_in_range(t: PackedFloat32Array) -> PackedFloat32Array:
    if component:
        return component.get_values_in_range(t)
    return GameSignal.fill_zeroes(t)


func _to_string():
    return "AuxTerminalOutput[%s]" % component_name()
