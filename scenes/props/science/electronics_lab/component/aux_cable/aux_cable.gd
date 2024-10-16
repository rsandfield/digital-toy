class_name AuxCable
extends Node3D


var _terminal_input: AuxTerminalInput
var _terminal_output: AuxTerminalOutput

var _plug_input: AuxPlug
var _plug_output: AuxPlug

func _ready():
    _plug_input = $PlugInput
    _plug_input.cable = self
    _plug_input.reparent.call_deferred(get_viewport())

    _plug_output = $PlugOutput
    _plug_output.cable = self
    _plug_output.reparent.call_deferred(get_viewport())

    $Rope3D.make()


func _physics_process(_delta):
    global_position = (_plug_input.global_position + _plug_output.global_position) * 0.5


func get_value_at_time(t: float) -> float:
    if _terminal_output:
        return _terminal_output.get_value_at_time(t)
    return 0


func get_values_in_range(t: PackedFloat32Array) -> PackedFloat32Array:
    if _terminal_output:
        return _terminal_output.get_values_in_range(t)
    return GameSignal.fill_zeroes(t)


func _on_plug_input_snapped_to(terminal: SnappableLock):
    _terminal_input = terminal


func _on_plug_input_released():
    _terminal_input = null


func _on_plug_output_snapped_to(terminal: SnappableLock):
    _terminal_output = terminal


func _on_plug_output_released():
    _terminal_output = null
