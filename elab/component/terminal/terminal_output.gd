class_name OutputTerminal
extends Terminal

func get_value_at_time(t: float) -> float:
	if component:
		return component.get_value_at_time(t)
	return 0
	
func get_values_in_range(t: PackedFloat32Array) -> PackedFloat32Array:
	return component.get_values_in_range(t)

func _to_string():
	return "OutputTerminal[%s]" % component_name()
