class_name SingingBabyAnt
extends Node3D

@export var tone: Tone
@export var input_pitch: float = 440

@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready():
    audio.pitch_scale = tone.pitch_correction(input_pitch)

func get_tone() -> Tone:
    return tone

func play():
    audio.play()
    await  audio.finished
