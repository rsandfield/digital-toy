class_name Grabbable
extends CollisionShape3D


@export var hover_shape := HUD.ReticleState.RING


func _ready():
    assert(get_parent())


func reticle_shape_on_hover() -> HUD.ReticleState:
    return hover_shape


func _on_interact_by_character(player: PlayerController):
    var parent = get_parent()
    if parent.has_method("_on_grab_by_character"):
        parent._on_grab_by_character(player)
    else:
        player._on_grab_object(parent)
