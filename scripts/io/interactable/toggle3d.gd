class_name Toggle3D
extends Area3D


signal toggled()


@export var light_when_on: bool = false
@export var unlit: StandardMaterial3D
@export var lit: StandardMaterial3D

@onready var _anim: AnimationPlayer
@onready var audio: AudioStreamPlayer3D

var _on := true
var _up := true


func _ready():
    _anim = get_node_or_null("AnimationPlayer")
    audio = get_node_or_null("AudioStreamPlayer3D")


func reticle_shape_on_hover() -> HUD.ReticleState:
    return HUD.ReticleState.CIRCLE


func set_lit(on: bool):
    var mat: StandardMaterial3D
    if lit && on:
        mat = lit
    if unlit && !on:
        mat = unlit

    if mat:
        $ButtonMesh.material_override = mat
    else:
        var state = "unlit"
        if on:
            state = "lit"
        push_error("%s does not have a material for %s state" % [name, state])


func _on_toggled():
    _on = !_on
    if light_when_on:
        set_lit(_on)
    toggled.emit()


func _toggle():
    _up = !_up
    if _anim:
        if _up:
            _anim.play("up")
        else:
            _anim.play("down")
    if audio:
        audio.play()


func _on_interact():
    if _anim && _anim.is_playing():
        return
    _toggle()
    _on_toggled()
