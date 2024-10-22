class_name Doinker
extends Button3D


@export var doinking_energy := 1.0
@export var selected_energy := 0.25

func doink():
    $OmniLight3D.light_energy = doinking_energy
    $OmniLight3D.visible = true
    $AudioStreamPlayer3D.play()


func undoink():
    $OmniLight3D.visible = false


func select():
    $OmniLight3D.light_energy = selected_energy