class_name FuzzyDice
extends Button3D


var _dice: Array[RigidBody3D]


func _ready():
    super()
    for child in get_children():
        if child is RigidBody3D:
            _dice.append(child)



func _on_interact():
    super()
    for die in _dice:
        var dir := die.position
        dir.y = 0
        die.apply_impulse(dir.normalized() * 0.1)
