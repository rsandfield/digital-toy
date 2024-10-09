class_name Grabbable
extends CollisionShape3D


func _ready():
    assert(get_parent().has_method("_on_grab_by_character"))


func _reticle_shape_on_hover() -> HUD.ReticleState:
    return HUD.ReticleState.RING


func _on_interact_by_character(player: PlayerController):
    get_parent()._on_grab_by_character(player)
