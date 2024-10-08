class_name InteractableComponent
extends Node


signal interacted()
signal interacted_by_character(character : CharacterBody3D)


@export var interactable_distance: float = -1


var characters_hovering = {}


func _ready():
    var parent = get_parent()
    if parent.has_method("_on_interact"):
        interacted.connect(parent._on_interact)
    if parent.has_method("_on_interact_by_character"):
        interacted.connect(parent._on_interact_by_character)


func interact_with(character : PlayerController):
    interacted.emit()
    interacted_by_character.emit(character)


func hover_cursor(character : PlayerController):
    characters_hovering[character] = Engine.get_process_frames()


func get_character_hovered_by_cur_camera() -> PlayerController:
    for character in characters_hovering.keys():
        var cur_cam = get_viewport().get_camera_3d() if get_viewport() else null
        if cur_cam != null and character.is_ancestor_of(cur_cam):
            return character
    return null


func _process(_delta):
    for character in characters_hovering.keys():
        if Engine.get_process_frames() - characters_hovering[character] > 1:
            characters_hovering.erase(character)
