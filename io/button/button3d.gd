class_name Button3D
extends Area3D

signal pressed()

@export var light_on_click: bool = false
@export var unlit: StandardMaterial3D
@export var lit: StandardMaterial3D

func input_event(_camera:Node, event:InputEvent, _position:Vector3, _normal:Vector3, _shape_idx:int):
	var mouse_click = event as InputEventMouseButton
	if mouse_click && mouse_click.button_index == 1 && mouse_click.pressed:
		on_click()

func on_click():
	pressed.emit()
	var anim = $AnimationPlayer
	anim.play("push")
	if light_on_click:
		set_lit(true)
	await anim.animation_finished
	if light_on_click:
		set_lit(false)

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
		print("%s does not have a material for %s state" % [name, state])
