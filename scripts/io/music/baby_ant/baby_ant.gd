class_name SingingBabyAnt
extends Node3D

@export var tone: Tone
@export var input_pitch: float = 440

var _accessory: BabyAntProp
var _default_stream: AudioStream

var _audio: AudioStreamPlayer3D
var _toggle_group: Node3D


func _ready():
    _audio = $AudioStreamPlayer3D
    _audio.pitch_scale = tone.pitch_correction(input_pitch)
    _default_stream = _audio.stream
    _toggle_group = $Baby/Head/ToggleGroup
    var snaplock = $Baby/SnappableLock as SnappableLock
    var maybe = NodeHelper.find_duck_child(self, "get_snap_group")
    if maybe:
        snaplock.force_assign(maybe)


func get_tone() -> Tone:
    return tone


func play():
    _audio.play()
    _toggle_group.visible = true
    await  _audio.finished
    _toggle_group.visible = false


func accessorize(accessory: BabyAntProp):
    _accessory = accessory
    if _accessory:
        _audio.stream = _accessory.stream
        _audio.pitch_scale = tone.pitch_correction(_accessory.input_pitch)
    else:
        _audio.stream = _default_stream
        _audio.pitch_scale = tone.pitch_correction(input_pitch)