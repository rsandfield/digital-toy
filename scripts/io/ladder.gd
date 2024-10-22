@tool
class_name Ladder
extends Area3D


@onready var top_of_ladder: Node3D = get_node_or_null("TopOfLadder")


func _ready():
    add_to_group("ladders")


func is_over_top(pos_y: float) -> bool :
    return pos_y > top_of_ladder.position.y

func _get_configuration_warnings():
    if !top_of_ladder:
        top_of_ladder = get_node_or_null("TopOfLadder")
        return ["Must have node named 'TopOfLadder'"]