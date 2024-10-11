class_name InteractableComponent
extends Node


signal interacted()
signal interacted_by_character(character : PlayerController)
signal used()
signal used_by_character(character: PlayerController)
signal hover_start(character: PlayerController)
signal hover_end(character: PlayerController)



@export var interactable_distance: float = -1


var characters_hovering = {}


func _ready():
    var parent = get_parent()
    NodeHelper.connect_signal(interacted, parent, "_on_interact")
    NodeHelper.connect_signal(interacted_by_character, parent, "_on_interact_by_character")
    NodeHelper.connect_signal(used, parent, "_on_used")
    NodeHelper.connect_signal(used_by_character, parent, "_on_used_by_character")
    NodeHelper.connect_signal(hover_start, parent, "_on_hover_start_by_character")
    NodeHelper.connect_signal(hover_end, parent, "_on_hover_end_by_character")


func interact_with(character : PlayerController):
    interacted.emit()
    interacted_by_character.emit(character)


func use_by(character: PlayerController):
    used.emit()
    used_by_character.emit(character)


func hover_cursor(character : PlayerController):
    characters_hovering[character] = Engine.get_process_frames()
    hover_start.emit(character)


func get_character_hovered_by_cur_camera() -> PlayerController:
    for character in characters_hovering.keys():
        var cur_cam = get_viewport().get_camera_3d() if get_viewport() else null
        if cur_cam != null and character.is_ancestor_of(cur_cam):
            return character
    return null


func get_reticle_state() -> HUD.ReticleState:
    var parent = get_parent()
    if parent.has_method("_reticle_shape_on_hover"):
        return parent._reticle_shape_on_hover()
    return HUD.ReticleState.PINPOINT


func _process(_delta):
    for character in characters_hovering.keys():
        if Engine.get_process_frames() - characters_hovering[character] > 1:
            characters_hovering.erase(character)
            hover_end.emit(character)
