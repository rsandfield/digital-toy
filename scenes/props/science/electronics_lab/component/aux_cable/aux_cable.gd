class_name AuxCable
extends Node3D


var _input: AuxTerminalOutput
var _output: AuxTerminalInput


func _ready():
    $PlugInput.cable = self
    $PlugOutput.cable = self


func get_value_at_time(t: float) -> float:
    if _input:
        return _input.get_value_at_time(t)
    return 0


func get_values_in_range(t: PackedFloat32Array) -> PackedFloat32Array:
    if _input:
        return _input.get_values_in_range(t)
    return GameSignal.fill_zeroes(t)


func _on_plug_input_snapped_to(terminal: SnappableLock):
    _output = terminal


func _on_plug_input_released():
    _output = null


func _on_plug_output_snapped_to(terminal: SnappableLock):
    _input = terminal


func _on_plug_output_released():
    _input = null
