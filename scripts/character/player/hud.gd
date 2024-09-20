class_name HUD
extends Node2D

enum ReticleState {
    PINPOINT,
    CIRCLE,
    RING,
    CROSSHAIR,
}

@export var color: Color
var _state: ReticleState

# Called when the node enters the scene tree for the first time.
func _ready():
    set_state(ReticleState.PINPOINT)


func set_state(state: ReticleState):
    _state = state

func _process(_delta):
    queue_redraw()

func _draw():
    var center = get_viewport_rect().size * 0.5
    match _state:
        ReticleState.PINPOINT:
            draw_circle(center, 8, color)
        ReticleState.CIRCLE:
            draw_circle(center, 1, color)
            draw_arc(center, 8, 0, TAU, 16, color, 1.0, true)
        ReticleState.RING:
            draw_arc(center, 8, 0, TAU, 16, color, 2.0, true)
            draw_arc(center, 12, PI * 0.1, PI * 0.4, 3, color, 2.0, true)
            draw_arc(center, 12, PI * 0.6, PI * 0.9, 3, color, 2.0, true)
            draw_arc(center, 12, PI * 1.1, PI * 1.4, 3, color, 2.0, true)
            draw_arc(center, 12, PI * 1.6, PI * 1.9, 3, color, 2.0, true)
        ReticleState.CROSSHAIR:
            var up = Vector2.UP * 6
            var right = Vector2.RIGHT * 6
            draw_line(center + up, center - up, color, 2)
            draw_line(center + right, center - right, color, 2)
