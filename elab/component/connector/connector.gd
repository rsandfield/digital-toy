@tool
class_name Connector
extends SignalCarrier3D

@export var input: OutputTerminal = null :
	get:
		return input
	set(value):
		if input:
			input.connection = self
		input = value
		if input:
			input.connection = self

@export var output: InputTerminal = null :
	get:
		return output
	set(value):
		if output:
			output.connection = null
		output = value
		if output:
			output.connection = self

# func deregister_terminal(t: Terminal):
#     pass

func get_value_at_time(t: float) -> float:
	if input:
		return input.get_value_at_time(t)
	return 0

func get_values_in_range(t: PackedFloat32Array) -> PackedFloat32Array:
	if input:
		return input.get_values_in_range(t)
	var r: PackedFloat32Array = []
	r.resize(len(t))
	r.fill(0.0)
	return r
