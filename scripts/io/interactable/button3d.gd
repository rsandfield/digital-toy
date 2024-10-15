class_name Button3D
extends Area3D


signal pressed()


@export var light_on_click: bool = false
@export var unlit: StandardMaterial3D
@export var lit: StandardMaterial3D

@onready var anim: AnimationPlayer
@onready var audio: AudioStreamPlayer3D


func _ready():
    anim = get_node_or_null("AnimationPlayer")
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


func _on_interact():
    pressed.emit()
    if anim:
        anim.play("push")
    if audio:
        audio.play()
    if light_on_click:
        set_lit(true)
    if anim:
        await anim.animation_finished
    if light_on_click:
        set_lit(false)
