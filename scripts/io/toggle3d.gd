class_name Toggle3D
extends Area3D


signal toggled(on: bool)


@export var light_when_on: bool = false
@export var unlit: StandardMaterial3D
@export var lit: StandardMaterial3D

@onready var anim: AnimationPlayer
@onready var audio: AudioStreamPlayer3D

var _on: bool
var _up: bool


func _ready():
    anim = get_node_or_null("AnimationPlayer")
    audio = get_node_or_null("AudioStreamPlayer3D")


func _reticle_shape_on_hover() -> HUD.ReticleState:
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


func _on_toggled(on: bool):
    _on = on
    if on && light_when_on:
        set_lit(true)
    if !on && light_when_on:
        set_lit(false)


func _toggle():
    _up = !_up
    if anim:
        if _up:
            anim.play("up")
        else:
            anim.play("down")
    if audio:
        audio.play()


func _on_interact():
    _toggle()
    _on_toggled(_on)
    toggled.emit(_on)