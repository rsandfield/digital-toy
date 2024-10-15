class_name Component
extends SignalCarrier3D

@export var inputs: Array[AuxTerminalInput]
@export var outputs: Array[AuxTerminalOutput]

func _ready():
    assert(
        len(inputs) + len(outputs) > 0,
        "Component[%s] must have at least one input or output" % name
    )
    _register_terminals(inputs)
    _register_terminals(outputs)

func _register_terminals(terminals: Array):
    if !terminals:
        return
    for i in len(terminals):
        terminals[i].register_component(self, i)

func get_value_at_time(t: float) -> float:
    var value = 0.0
    for i in inputs:
        value += i.get_value_at_time(t)
    return value


func on_grab_by_character(character: PlayerController):
    character.on_grab_object(self)


func _to_string():
    return "Component[%s]" % name
